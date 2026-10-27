package com.franco.desco.domain.report;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ReportModels {

    private ReportModels() {
    }

    public record CatalogItem(
            String codigo,
            String nombre,
            String grupo,
            String descripcion
    ) {
    }

    public record Section(
            String codigo,
            List<Map<String, Object>> filas
    ) {
        public Section {
            filas = filas == null
                    ? List.of()
                    : filas.stream()
                    .map(ReportModels::immutableRow)
                    .toList();
        }
    }

    public record Data(
            String reporte,
            List<Section> secciones
    ) {
        public Data {
            secciones = secciones == null
                    ? List.of()
                    : List.copyOf(secciones);
        }
    }

    private static Map<String, Object> immutableRow(
            Map<String, Object> row
    ) {
        return row == null
                ? Map.of()
                : Collections.unmodifiableMap(
                        new LinkedHashMap<>(row)
                );
    }
}
