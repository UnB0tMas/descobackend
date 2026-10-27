package com.franco.desco.adapter.in.web.dashboard;

import com.franco.desco.domain.dashboard.DashboardModels;
import org.springframework.stereotype.Component;

@Component
public class DashboardWebMapper {

    public DashboardResponses.Summary response(
            DashboardModels.Summary source
    ) {
        DashboardResponses.Period period = source.periodo() == null
                ? null
                : new DashboardResponses.Period(
                        source.periodo().desde(),
                        source.periodo().hasta()
                );

        return new DashboardResponses.Summary(
                period,
                source.indicadores()
                        .stream()
                        .map(this::indicator)
                        .toList(),
                source.graficos()
                        .stream()
                        .map(this::graph)
                        .toList(),
                source.alertas()
                        .stream()
                        .map(this::alert)
                        .toList(),
                source.accesosRapidos()
                        .stream()
                        .map(this::shortcut)
                        .toList()
        );
    }

    private DashboardResponses.Indicator indicator(
            DashboardModels.Indicator source
    ) {
        return new DashboardResponses.Indicator(
                source.codigo(),
                source.indicador(),
                source.valor(),
                source.unidad(),
                source.icono(),
                source.orden()
        );
    }

    private DashboardResponses.Graph graph(
            DashboardModels.Graph source
    ) {
        return new DashboardResponses.Graph(
                source.codigo(),
                source.titulo(),
                source.subtitulo(),
                source.tipoGrafico(),
                source.unidad(),
                source.ancho(),
                source.orden(),
                source.series()
                        .stream()
                        .map(series -> new DashboardResponses.GraphSeries(
                                series.nombre(),
                                series.puntos()
                                        .stream()
                                        .map(point ->
                                                new DashboardResponses.GraphPoint(
                                                        point.categoria(),
                                                        point.valor(),
                                                        point.orden()
                                                )
                                        )
                                        .toList()
                        ))
                        .toList()
        );
    }

    private DashboardResponses.Alert alert(
            DashboardModels.Alert source
    ) {
        return new DashboardResponses.Alert(
                source.tipo(),
                source.mensaje(),
                source.cantidad(),
                source.orden()
        );
    }

    private DashboardResponses.Shortcut shortcut(
            DashboardModels.Shortcut source
    ) {
        return new DashboardResponses.Shortcut(
                source.moduloId(),
                source.codigoModulo(),
                source.nombreModulo(),
                source.ruta(),
                source.icono(),
                source.orden()
        );
    }
}
