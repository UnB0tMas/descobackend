package com.franco.desco.application.caja;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.time.LocalTime;
import java.util.List;

@Service
public class AtencionSemanalService {
    private final AtencionSemanalRepository repository;
    public AtencionSemanalService(AtencionSemanalRepository repository) { this.repository = repository; }

    public record Resultado(List<AtencionSemanalRepository.Afectado> afectados, String mensaje) {}
    public static final class Rechazo extends RuntimeException {
        private final int http;
        public Rechazo(String mensaje, int http) { super(mensaje); this.http = http; }
        public int http() { return http; }
    }
    private final JsonMapper json = new JsonMapper();

    @Transactional(rollbackFor = RuntimeException.class)
    public Resultado ejecutarLote(String accion, long usuario, long uot, List<Integer> dias,
                                  String inicio, String fin, boolean ajustar, String vistaConfirmada) {
        if (!"PREVISUALIZAR".equals(accion) && !"APLICAR".equals(accion))
            throw new Rechazo("No se pudo completar la operación.", 400);
        if (dias == null || dias.isEmpty() || dias.size() > 7 || dias.stream().anyMatch(d -> d == null || d < 1 || d > 7)
            || new HashSet<>(dias).size() != dias.size())
            throw new Rechazo("Selecciona días válidos.", 400);

        // Validar toda la petición antes de comenzar cualquier escritura.
        if (inicio == null || fin == null || !inicio.matches("\\d{2}:\\d{2}")
            || !fin.matches("\\d{2}:\\d{2}"))
            throw new Rechazo("Revisa las horas seleccionadas.", 400);
        try {
            if (!LocalTime.parse(inicio).isBefore(LocalTime.parse(fin)))
                throw new Rechazo("Revisa las horas seleccionadas.", 400);
        } catch (java.time.format.DateTimeParseException ex) {
            throw new Rechazo("Revisa las horas seleccionadas.", 400);
        }

        Map<Integer, String> vistas = new LinkedHashMap<>();
        if ("APLICAR".equals(accion) && ajustar) {
            if (vistaConfirmada == null) throw new Rechazo("Revisa nuevamente los horarios.", 409);
            try {
                var items = json.readTree(vistaConfirmada);
                if (!items.isArray()) throw new IllegalArgumentException();
                for (Integer dia : dias) {
                    var filtrados = new ArrayList<Map<String, Object>>();
                    for (var item : items) {
                        int numeroDia = item.path("diaSemana").asInt(-1);
                        if (!dias.contains(numeroDia) || item.path("horarioId").asLong(0) <= 0)
                            throw new IllegalArgumentException();
                        if (numeroDia == dia) filtrados.add(Map.of(
                            "horarioId", item.path("horarioId").asLong(),
                            "horaInicio", item.path("horaInicio").asText(),
                            "horaFin", item.path("horaFin").asText()));
                    }
                    vistas.put(dia, json.writeValueAsString(filtrados));
                }
            } catch (RuntimeException ex) {
                throw new Rechazo("Revisa nuevamente los horarios.", 409);
            }
        }
        var afectados = new ArrayList<AtencionSemanalRepository.Afectado>();
        for (Integer dia : dias.stream().sorted().toList()) {
            var resultado = ejecutar(accion, usuario, uot, "PERSONALIZAR", dia, inicio, fin,
                                    ajustar, vistas.get(dia));
            afectados.addAll(resultado.afectados());
        }
        return new Resultado(List.copyOf(afectados), "APLICAR".equals(accion)
                ? "Horario actualizado." : "Consulta realizada.");
    }

    public Resultado ejecutar(String accion, long usuario, long uot, String modo, Integer dia,
                              String inicio, String fin, boolean ajustar, String vistaConfirmada) {
        if (!List.of("GENERAL", "PERSONALIZAR", "HEREDAR").contains(modo)
            || (!"GENERAL".equals(modo) && (dia == null || dia < 1 || dia > 7))
            || ("GENERAL".equals(modo) && dia != null))
            throw new Rechazo("Revisa el día seleccionado.", 400);
        LocalTime desde = null, hasta = null;
        if (!"HEREDAR".equals(modo)) {
            try {
                if (inicio == null || fin == null || !inicio.matches("\\d{2}:\\d{2}")
                    || !fin.matches("\\d{2}:\\d{2}")) throw new IllegalArgumentException();
                desde = LocalTime.parse(inicio);
                hasta = LocalTime.parse(fin);
                if (!desde.isBefore(hasta)) throw new IllegalArgumentException();
            } catch (RuntimeException ex) { throw new Rechazo("Revisa las horas seleccionadas.", 400); }
        }
        var r = repository.ejecutar(accion, usuario, uot, modo, dia, desde, hasta, ajustar, vistaConfirmada);
        if (!r.exitoso()) throw new Rechazo(r.mensaje(), r.http());
        return new Resultado(r.afectados(), r.mensaje());
    }
}
