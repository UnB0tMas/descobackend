package com.franco.desco.application.expense;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExpenseCommands {
    private ExpenseCommands() {}

    public record Filter(Long campaniaVentaId, Long operativoVentaId, String estadoProceso) {}
    public record ListExpenses(PageRequest<Filter> page) {}
    public record GetExpense(Long gastoCampaniaId) {}

    public record Create(
            Long campaniaVentaId,
            Long operativoVentaId,
            Short tipoGastoId,
            Short reglaProrrateoId,
            LocalDate fecha,
            String concepto,
            BigDecimal importe,
            String moneda
    ) {}

    public record Update(
            Long gastoCampaniaId,
            Short tipoGastoId,
            Short reglaProrrateoId,
            LocalDate fecha,
            String concepto,
            BigDecimal importe,
            String moneda
    ) {}

    public record ManualShare(Long participacionId, BigDecimal importeAsignado) {}
    public record Prorate(Long gastoCampaniaId, List<ManualShare> prorrateo) {}
    public record Approve(Long gastoCampaniaId) {}
    public record Cancel(Long gastoCampaniaId, String motivo) {}
}
