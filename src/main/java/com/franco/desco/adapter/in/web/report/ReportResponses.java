package com.franco.desco.adapter.in.web.report;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;
import java.util.Map;

public final class ReportResponses {

    private ReportResponses() {
    }

    @Schema(name = "ReportCatalogItemResponse")
    public record CatalogItem(
            String codigo,
            String nombre,
            String grupo,
            String descripcion
    ) {
    }

    @Schema(
            name = "ReportSectionResponse",
            description = "Sección del reporte. Las columnas de cada fila son definidas por el PA correspondiente."
    )
    public record Section(
            @Schema(example = "CASOS_FITOSANITARIOS")
            String codigo,
            List<Map<String, Object>> filas
    ) {
    }

    @Schema(
            name = "ReportDataResponse",
            description = "Reporte polimórfico organizado por secciones. SQL Server conserva la lógica y la forma de cada conjunto de datos."
    )
    public record Data(
            String reporte,
            List<Section> secciones
    ) {
    }
}
