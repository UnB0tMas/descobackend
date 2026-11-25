package com.franco.desco.application.caja;

import org.springframework.stereotype.Service;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.List;

/** Los turnos definidos se copian por horas al asignarlos; no alteran asignaciones anteriores. */
@Service
public class PlantillaHorarioService {
    public static final class Rechazo extends RuntimeException {
        private final int http;
        public Rechazo(String mensaje, int http) { super(mensaje); this.http = http; }
        public int http() { return http; }
    }

    private final PlantillaHorarioRepository repository;

    public PlantillaHorarioService(PlantillaHorarioRepository repository) {
        this.repository = repository;
    }

    public List<PlantillaHorarioRepository.Plantilla> listar(long usuario, long uot) {
        return verificar(repository.ejecutar("LISTAR", usuario, uot, null, null, null, null)).plantillas();
    }

    public HorarioComercialService.Resultado guardar(long usuario, long uot, Long id,
                                                      String nombre, String desde, String hasta) {
        if (nombre == null || nombre.trim().length() < 2 || nombre.trim().length() > 80)
            throw new CajaPosService.Regla("Indica un nombre válido.");
        LocalTime inicio = hora(desde);
        LocalTime fin = hora(hasta);
        if (!inicio.isBefore(fin)) throw new CajaPosService.Regla("Revisa las horas seleccionadas.");
        verificar(repository.ejecutar("GUARDAR", usuario, uot, id, nombre.trim(), inicio, fin));
        return new HorarioComercialService.Resultado(uot, "Turno guardado.");
    }

    public HorarioComercialService.Resultado desactivar(long usuario, long uot, long id) {
        verificar(repository.ejecutar("DESACTIVAR", usuario, uot, id, null, null, null));
        return new HorarioComercialService.Resultado(uot, "Turno eliminado.");
    }

    private LocalTime hora(String valor) {
        if (valor == null || !valor.matches("([01][0-9]|2[0-3]):[0-5][0-9]"))
            throw new CajaPosService.Regla("Revisa las horas seleccionadas.");
        try { return LocalTime.parse(valor); }
        catch (DateTimeParseException ex) { throw new CajaPosService.Regla("Revisa las horas seleccionadas."); }
    }

    private PlantillaHorarioRepository.Respuesta verificar(PlantillaHorarioRepository.Respuesta respuesta) {
        if (!respuesta.exitoso()) throw new Rechazo(respuesta.mensaje(), respuesta.http());
        return respuesta;
    }
}
