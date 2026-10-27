package com.franco.desco.domain.incident;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class IncidentModels {
    private IncidentModels() {}

    public record Summary(
            Long incidenciaId,
            Long operativoVentaId,
            String operativo,
            Long entregaSocioId,
            String codigoLote,
            String tipoIncidencia,
            Instant fechaHora,
            BigDecimal pesoAfectadoKg,
            String severidad,
            String descripcion,
            String estadoIncidencia
    ) {}

    public record Attachment(
            Long archivoId,
            String nombreOriginal,
            String mimeType,
            String secureUrl,
            String categoria,
            String descripcion
    ) {}

    public record Detail(
            Summary incidencia,
            List<Attachment> archivos
    ) {
        public Detail {
            archivos = archivos == null ? List.of() : List.copyOf(archivos);
        }
    }
}
