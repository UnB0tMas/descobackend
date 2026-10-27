package com.franco.desco.adapter.in.web.report;

import com.franco.desco.application.report.ReportCommands;
import com.franco.desco.domain.report.ReportModels;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Component
public class ReportWebMapper {

    public ReportCommands.GetData data(
            String report,
            LocalDate from,
            LocalDate to,
            Long campaign,
            Long operation,
            Long zone
    ) {
        return new ReportCommands.GetData(
                new ReportCommands.Filters(
                        report,
                        from,
                        to,
                        campaign,
                        operation,
                        zone
                )
        );
    }

    public ReportCommands.ExportData export(
            String report,
            LocalDate from,
            LocalDate to,
            Long campaign,
            Long operation,
            Long zone
    ) {
        return new ReportCommands.ExportData(
                new ReportCommands.Filters(
                        report,
                        from,
                        to,
                        campaign,
                        operation,
                        zone
                )
        );
    }

    public ReportResponses.CatalogItem response(
            ReportModels.CatalogItem value
    ) {
        return new ReportResponses.CatalogItem(
                value.codigo(),
                value.nombre(),
                value.grupo(),
                value.descripcion()
        );
    }

    public ReportResponses.Data response(
            ReportModels.Data value
    ) {
        return new ReportResponses.Data(
                value.reporte(),
                value.secciones()
                        .stream()
                        .map(this::response)
                        .toList()
        );
    }

    private ReportResponses.Section response(
            ReportModels.Section value
    ) {
        return new ReportResponses.Section(
                value.codigo(),
                value.filas()
        );
    }
}
