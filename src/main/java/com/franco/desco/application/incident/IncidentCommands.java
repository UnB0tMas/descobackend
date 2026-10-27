package com.franco.desco.application.incident;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;

public final class IncidentCommands {
    private IncidentCommands() {}

    public record Filter(
            Long operativoVentaId,
            Long entregaSocioId,
            String estadoIncidencia,
            String tipoIncidencia,
            String severidad
    ) {}

    public record ListIncidents(PageRequest<Filter> page) {}
    public record GetIncident(Long incidenciaId) {}

    public record Create(
            Long operativoVentaId,
            Long entregaSocioId,
            String tipoIncidencia,
            BigDecimal pesoAfectadoKg,
            String severidad,
            String descripcion
    ) {}

    public record Review(
            Long incidenciaId,
            BigDecimal pesoAfectadoKg,
            String severidad,
            String descripcion
    ) {}

    public record Resolve(Long incidenciaId, String motivo) {}
    public record Cancel(Long incidenciaId, String motivo) {}
}
