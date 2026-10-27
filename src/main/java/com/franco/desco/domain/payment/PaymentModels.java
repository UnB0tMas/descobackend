package com.franco.desco.domain.payment;

import java.math.BigDecimal;
import java.time.Instant;

public final class PaymentModels {
    private PaymentModels() {}

    public record Summary(
            Long pagoSocioId, Long liquidacionSocioId, Instant fechaHora,
            BigDecimal importe, String medioPago, String numeroOperacion,
            String estadoProceso, BigDecimal importeNeto, String numeroDocumento,
            String socioNombre, BigDecimal saldoPosteriorPago
    ) {}

    public record Detail(
            Long pagoSocioId, Long liquidacionSocioId, Instant fechaHora,
            BigDecimal importe, String medioPago, String numeroOperacion,
            String estadoProceso, boolean estado, BigDecimal importeNeto,
            BigDecimal totalConfirmadoHastaPago, BigDecimal saldoPosteriorPago,
            BigDecimal totalPagadoActual, BigDecimal saldoPendienteActual,
            BigDecimal saldoPendiente
    ) {}
}
