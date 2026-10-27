package com.franco.desco.application.liquidation;

import com.franco.desco.application.shared.pagination.PageRequest;

public final class LiquidationCommands {
    private LiquidationCommands() {}

    public record Filter(Long campaniaVentaId, Long participacionId, String estadoProceso) {}
    public record ListLiquidations(PageRequest<Filter> page) {}
    public record GetLiquidation(Long liquidacionSocioId) {}
    public record Calculate(Long participacionId) {}
    public record Recalculate(Long liquidacionSocioId, String motivo) {}
    public record Approve(Long liquidacionSocioId) {}
    public record Cancel(Long liquidacionSocioId, String motivo) {}
}
