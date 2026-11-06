package com.franco.desco.domain.fieldtrip;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class E2Models {
    private E2Models() {}

    public record Operation(Long salidaId, Long visitaId, String estado) {}
    public record Option(Long id, String nombre, String codigo) {}
    public record ResourceOption(Long id, String tipo, String nombre, String codigo,
                                 String unidad, BigDecimal disponible) {}
    public record Catalogs(List<Option> motivos, List<Option> tiposVisita,
                           List<ResourceOption> bienes, List<Option> participantes) {}
    public record Row(Long salidaId, String nombre, String estado, Instant fechaSolicitud,
                      Instant fechaFinPrevista, Instant fechaInicioPrevista, Long solicitanteEmpleadoId) {}
    public record ListResult(Long total, List<Row> items) {}
    public record Destino(Long destinoId, Long predioId, String referencia, Integer orden, String actividadPrevista) {}
    public record Participante(Long empleadoId, String nombre, String funcion, Boolean responsable) {}
    public record Bien(Long solicitudRecursoId, Long bienId, Long suministroId, String tipo,
                       String codigo, String nombre, String unidad, BigDecimal cantidadSolicitada,
                       BigDecimal cantidadDevueltaDeclarada, BigDecimal cantidadDevueltaValidada,
                       String estado, String resultadoDeclarado, String resultadoValidado,
                       String observacion, String observacionValidacion) {}
    public record Visita(Long visitaId, Long destinoId, Long predioId, Instant fechaInicio, Instant fechaFin,
                         String estado, String objetivo, String resumen, String recomendaciones,
                         String tipoVisita) {}
    public record Evento(Long eventoId, String tipo, String detalle, Long usuarioId, Instant fechaHora) {}
    public record Detail(Long salidaId, String nombre, String estado, Long uotId, Long convenioId,
                         Long solicitanteEmpleadoId, Instant fechaSolicitud, Integer motivoSalidaId,
                         String descripcion, Instant fechaInicioPrevista, Instant fechaFinPrevista,
                         Instant fechaInicioReal, Instant fechaFinReal, Instant fechaAprobacion,
                         List<Destino> destinos, List<Participante> participantes, List<Bien> bienes,
                         List<Visita> visitas, List<Evento> historial, String observacionRetorno,
                         String justificacionSinVisita, String observacionInspeccion) {}
}
