package com.franco.desco.domain.fieldtrip;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/** Contratos de consulta: una salida contiene varias visitas y actuaciones. */
public final class SalidaPersonalModels {
    private SalidaPersonalModels() {}

    public record Resumen(Long salidaId, String codigo, String nombre, String estado,
            Instant fechaSolicitud, Instant fechaInicioPrevista, Instant fechaFinPrevista,
            String destinosResumen, Long visitas, Boolean puedeCancelar) {}
    public record Lista(Long total, List<Resumen> items) {}
    public record Destino(Long destinoId, Long predioId, String nombrePredio,
            String codigoPredio, String referencia, String actividadPrevista, Integer orden) {}
    public record Visita(Long visitaId, Long predioId, String tipoVisita, String objetivo,
            String resumen, String recomendaciones, String estado, Instant fechaInicio,
            Instant fechaFin, Boolean iniciadaPorMi, Boolean finalizadaPorMi) {}
    public record Actuacion(Long actuacionId, Long visitaId, Long predioId,
            String tipo, String observacion, Instant fecha) {}
    public record Consumo(Long consumoId, Long visitaId, Long predioId, Long tratamientoId,
            Long solicitudRecursoId, String suministro, BigDecimal cantidad, String unidad,
            String lote, BigDecimal cantidadSolicitadaSalida,
            BigDecimal cantidadDevueltaValidadaSalida, String tratamiento, Instant fecha) {}
    public record Evidencia(Long archivoId, String nombre, String descripcion,
            Long visitaId, Long predioId, Instant fecha) {}
    public record Evento(Long eventoId, String tipo, String detalle,
            Long usuarioId, String usuario, Instant fecha) {}
    public record Detalle(Long salidaId, String codigo, String nombre, String estado,
            Long uotId, String solicitanteNombre, Instant fechaSolicitud, Instant fechaInicioPrevista,
            Instant fechaFinPrevista, Instant fechaInicioReal, Instant fechaFinReal,
            Boolean puedeCancelar, Long documentoId, List<Destino> destinos,
            List<Visita> visitas, List<Actuacion> actuaciones, List<Consumo> consumos,
            List<Evidencia> evidencias, List<Evento> historialPropio,
            List<Evento> historialExpediente) {}
}
