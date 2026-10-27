package com.franco.desco.application.buyercollection;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;

public final class BuyerCollectionCommands {
    private BuyerCollectionCommands() {}

    public record Filter(Long campaniaVentaId, Long operativoVentaId, String estadoProceso) {}
    public record ListCollections(PageRequest<Filter> page) {}
    public record GetBalance(Long campaniaVentaId, Long operativoVentaId) {}
    public record CreateCollection(Long campaniaVentaId, Long operativoVentaId, BigDecimal importe, String moneda, String medioPago, String numeroOperacion) {}
    public record ConfirmCollection(Long cobroCompradorId) {}
    public record CancelCollection(Long cobroCompradorId, String motivo) {}
}
