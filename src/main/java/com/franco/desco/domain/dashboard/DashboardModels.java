package com.franco.desco.domain.dashboard;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class DashboardModels {

    private DashboardModels() {
    }

    public record Filter(
            LocalDate desde,
            LocalDate hasta
    ) {
    }

    public record Period(
            LocalDate desde,
            LocalDate hasta
    ) {
    }

    public record Indicator(
            String codigo,
            String indicador,
            BigDecimal valor,
            String unidad,
            String icono,
            Integer orden
    ) {
    }

    public record Alert(
            String tipo,
            String mensaje,
            Long cantidad,
            Integer orden
    ) {
    }

    public record Shortcut(
            Integer moduloId,
            String codigoModulo,
            String nombreModulo,
            String ruta,
            String icono,
            Integer orden
    ) {
    }

    public record GraphPoint(
            String categoria,
            BigDecimal valor,
            Integer orden
    ) {
    }

    public record GraphSeries(
            String nombre,
            List<GraphPoint> puntos
    ) {
        public GraphSeries {
            puntos = puntos == null
                    ? List.of()
                    : List.copyOf(puntos);
        }
    }

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
        public Graph {
            series = series == null
                    ? List.of()
                    : List.copyOf(series);
        }
    }

    public record Summary(
            Period periodo,
            List<Indicator> indicadores,
            List<Graph> graficos,
            List<Alert> alertas,
            List<Shortcut> accesosRapidos
    ) {
        public Summary {
            indicadores = indicadores == null
                    ? List.of()
                    : List.copyOf(indicadores);
            graficos = graficos == null
                    ? List.of()
                    : List.copyOf(graficos);
            alertas = alertas == null
                    ? List.of()
                    : List.copyOf(alertas);
            accesosRapidos = accesosRapidos == null
                    ? List.of()
                    : List.copyOf(accesosRapidos);
        }
    }
}
