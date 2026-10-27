package com.franco.desco.adapter.in.web.dashboard;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class DashboardResponses {

    private DashboardResponses() {
    }

    @Schema(name = "DashboardPeriodResponse")
    public record Period(
            LocalDate desde,
            LocalDate hasta
    ) {
    }

    @Schema(name = "DashboardIndicatorResponse")
    public record Indicator(
            String codigo,
            String indicador,
            BigDecimal valor,
            String unidad,
            String icono,
            Integer orden
    ) {
    }

    @Schema(name = "DashboardAlertResponse")
    public record Alert(
            String tipo,
            String mensaje,
            Long cantidad,
            Integer orden
    ) {
    }

    @Schema(name = "DashboardShortcutResponse")
    public record Shortcut(
            Integer moduloId,
            String codigoModulo,
            String nombreModulo,
            String ruta,
            String icono,
            Integer orden
    ) {
    }

    @Schema(name = "DashboardGraphPointResponse")
    public record GraphPoint(
            String categoria,
            BigDecimal valor,
            Integer orden
    ) {
    }

    @Schema(name = "DashboardGraphSeriesResponse")
    public record GraphSeries(
            String nombre,
            List<GraphPoint> puntos
    ) {
    }

    @Schema(name = "DashboardGraphResponse")
    public record Graph(
            String codigo,
            String titulo,
            String subtitulo,
            String tipoGrafico,
            String unidad,
            Integer ancho,
            Integer orden,
            List<GraphSeries> series
    ) {
    }

    @Schema(name = "DashboardSummaryResponse")
    public record Summary(
            Period periodo,
            List<Indicator> indicadores,
            List<Graph> graficos,
            List<Alert> alertas,
            List<Shortcut> accesosRapidos
    ) {
    }
}
