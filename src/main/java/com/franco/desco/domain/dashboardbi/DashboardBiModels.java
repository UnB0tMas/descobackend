package com.franco.desco.domain.dashboardbi;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Contrato de lectura del BI de Reportes y Control; no incluye convenios especiales. */
public final class DashboardBiModels {
    private DashboardBiModels() {}

    public record Filter(String tab, LocalDate desde, LocalDate hasta, Long almacenId, Long predioId) {}

    public record Option(Long id, String nombre) {}

    public record Segmenters(String contexto, List<Option> almacenes, List<Option> predios) {
        public Segmenters {
            almacenes = almacenes == null ? List.of() : List.copyOf(almacenes);
            predios = predios == null ? List.of() : List.copyOf(predios);
        }
    }

    public record Kpi(String codigo, String titulo, BigDecimal valor, String unidad, Integer orden) {}

    /** Un punto por categoría y serie; la composición de gráficos corresponde al cliente. */
    public record Point(String grafico, String categoria, String serie, BigDecimal valor, Integer orden) {}

    public record Snapshot(LocalDate desde, LocalDate hasta, String tab, Long uotId,
                           List<Kpi> indicadores, List<Point> puntos) {
        public Snapshot {
            indicadores = indicadores == null ? List.of() : List.copyOf(indicadores);
            puntos = puntos == null ? List.of() : List.copyOf(puntos);
        }
    }
}
