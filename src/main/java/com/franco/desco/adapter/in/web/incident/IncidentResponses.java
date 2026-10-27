package com.franco.desco.adapter.in.web.incident;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class IncidentResponses {
    private IncidentResponses() {}

    @Schema(name="IncidentCreatedResponse")
    public record Created(Long incidenciaId) {}

    @Schema(name="IncidentSummaryResponse")
    public record Summary(
            Long incidenciaId, Long operativoVentaId, String operativo, Long entregaSocioId,
            String codigoLote, String tipoIncidencia, Instant fechaHora, BigDecimal pesoAfectadoKg,
            String severidad, String descripcion, String estadoIncidencia
    ) {}

    @Schema(name="IncidentAttachmentResponse")
    public record Attachment(
            Long archivoId, String nombreOriginal, String mimeType,
            String secureUrl, String categoria, String descripcion
    ) {}

    @Schema(name="IncidentDetailResponse")
    public record Detail(Summary incidencia, List<Attachment> archivos) {}
}
