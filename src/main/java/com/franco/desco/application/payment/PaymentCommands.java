package com.franco.desco.application.payment;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;

public final class PaymentCommands {
    private PaymentCommands() {}

    public record Filter(Long liquidacionSocioId, String estadoProceso) {}
    public record ListPayments(PageRequest<Filter> page) {}
    public record GetPayment(Long pagoSocioId) {}
    public record CreatePayment(Long liquidacionSocioId, BigDecimal importe, String medioPago, String numeroOperacion) {}
    public record ConfirmPayment(Long pagoSocioId) {}
    public record CancelPayment(Long pagoSocioId, String motivo) {}
}
