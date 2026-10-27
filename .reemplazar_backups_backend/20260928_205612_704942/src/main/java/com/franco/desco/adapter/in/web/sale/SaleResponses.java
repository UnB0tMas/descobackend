package com.franco.desco.adapter.in.web.sale;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class SaleResponses {
    private SaleResponses() {}

    @Schema(name = "SaleSummaryResponse")
    public record Summary(
            Long ventaId,
            Long uotId,
            String uotNombre,
            Long almacenId,
            String almacen,
            LocalDateTime fechaHora,
            LocalDateTime reservaHasta,
            String estadoVenta,
            String moneda,
            BigDecimal total,
            BigDecimal pagado,
            BigDecimal saldo,
            String cliente,
            Long usuarioVendedorId
    ) {}

    @Schema(name = "SaleLineResponse")
    public record Line(
            Long detalleVentaId,
            Long productoId,
            String producto,
            BigDecimal cantidad,
            Long productoPrecioId,
            BigDecimal precioUnitario,
            BigDecimal descuentoUnitario,
            BigDecimal subtotal
    ) {}

    @Schema(name = "SalePaymentResponse")
    public record Payment(
            Long pagoVentaId,
            Integer metodoPagoId,
            String metodoPago,
            BigDecimal importe,
            String moneda,
            String numeroOperacion,
            LocalDateTime fechaHora,
            Long usuarioId,
            String estadoPago
    ) {}

    @Schema(name = "SaleReceiptResponse")
    public record Receipt(
            String tipo,
            Long comprobanteId,
            String serie,
            Long numero,
            LocalDateTime fechaEmision
    ) {}

    @Schema(name = "SaleDetailResponse")
    public record Detail(
            Summary venta,
            List<Line> detalle,
            List<Payment> pagos,
            Receipt comprobante
    ) {}

    @Schema(name = "SalePaymentMethodResponse")
    public record PaymentMethod(
            Integer metodoPagoId,
            String codigo,
            String nombre,
            boolean requiereNumeroOperacion
    ) {}

    @Schema(name = "SaleCreatedResponse")
    public record Created(Long ventaId) {}

    @Schema(name = "SalePaymentCreatedResponse")
    public record PaymentCreated(Long pagoVentaId) {}

    @Schema(name = "SaleReceiptCreatedResponse")
    public record ReceiptCreated(Long comprobanteId) {}
}
