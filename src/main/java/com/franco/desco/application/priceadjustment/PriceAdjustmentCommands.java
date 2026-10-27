package com.franco.desco.application.priceadjustment;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;

public final class PriceAdjustmentCommands {
    private PriceAdjustmentCommands() {}

    public record Filter(Long participacionId, Long operativoVentaId) {}
    public record ListAdjustments(PageRequest<Filter> page) {}
    public record GetImpact(Long ajustePrecioSocioId) {}

    public record Create(
            Long participacionId,
            Long operativoVentaId,
            Long condicionComercialId,
            String tipoAjuste,
            BigDecimal precioOriginal,
            BigDecimal precioAplicado,
            BigDecimal montoAjuste,
            BigDecimal porcentajeAjuste,
            String motivo
    ) {}

    public record Cancel(Long ajustePrecioSocioId, String motivo) {}
}
