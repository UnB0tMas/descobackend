package com.franco.desco.adapter.in.web.buyercollection;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;

public final class BuyerCollectionResponses {
    private BuyerCollectionResponses() {}

    @Schema(name="BuyerCollectionSummaryResponse")
    public record Summary(Long cobroCompradorId,Long campaniaVentaId,String campania,Long operativoVentaId,String operativo,Instant fechaHora,BigDecimal importe,String moneda,String medioPago,String numeroOperacion,String estadoProceso) {}

    @Schema(name="BuyerBalanceResponse")
    public record Balance(Long campaniaVentaId,Long operativoVentaId,BigDecimal totalValorizado,BigDecimal totalCobrado,BigDecimal saldoPendiente) {}

    @Schema(name="BuyerCollectionCreatedResponse")
    public record Created(Long cobroCompradorId) {}
}
