package com.franco.desco.domain.buyercollection;

import java.math.BigDecimal;
import java.time.Instant;

public final class BuyerCollectionModels {
    private BuyerCollectionModels() {}

    public record Summary(
            Long cobroCompradorId, Long campaniaVentaId, String campania,
            Long operativoVentaId, String operativo, Instant fechaHora,
            BigDecimal importe, String moneda, String medioPago,
            String numeroOperacion, String estadoProceso
    ) {}

    public record Balance(
            Long campaniaVentaId, Long operativoVentaId,
            BigDecimal totalValorizado, BigDecimal totalCobrado,
            BigDecimal saldoPendiente
    ) {}
}
