package com.franco.desco.domain.expense;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExpenseModels {
    private ExpenseModels() {}

    public record Summary(
            Long gastoCampaniaId,
            Long campaniaVentaId,
            String campania,
            Long operativoVentaId,
            String operativo,
            Short tipoGastoId,
            String tipoGasto,
            Short reglaProrrateoId,
            String reglaProrrateo,
            LocalDate fecha,
            String concepto,
            BigDecimal importe,
            String moneda,
            String estadoProceso,
            BigDecimal totalProrrateado
    ) {}

    public record Proration(
            Long gastoProrrateoSocioId,
            Long participacionId,
            BigDecimal importeAsignado,
            String numeroDocumento,
            String socioNombre
    ) {}

    public record Detail(
            Long gastoCampaniaId,
            Long campaniaVentaId,
            Long operativoVentaId,
            Short tipoGastoId,
            String tipoGasto,
            Short reglaProrrateoId,
            String reglaProrrateo,
            LocalDate fecha,
            String concepto,
            BigDecimal importe,
            String moneda,
            String estadoProceso,
            boolean estado,
            List<Proration> prorrateo
    ) {
        public Detail {
            prorrateo = prorrateo == null ? List.of() : List.copyOf(prorrateo);
        }
    }
}
