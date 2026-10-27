package com.franco.desco.adapter.in.web.payment;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;

public final class PaymentResponses {
    private PaymentResponses() {}

    @Schema(name="PaymentSummaryResponse")
    public record Summary(
            Long pagoSocioId, Long liquidacionSocioId, Instant fechaHora, BigDecimal importe,
            String medioPago, String numeroOperacion, String estadoProceso, BigDecimal importeNeto,
            String numeroDocumento, String socioNombre, BigDecimal saldoPosteriorPago
    ) {}

    @Schema(name="PaymentDetailResponse")
    public record Detail(
            Long pagoSocioId, Long liquidacionSocioId, Instant fechaHora, BigDecimal importe,
            String medioPago, String numeroOperacion, String estadoProceso, boolean estado,
            BigDecimal importeNeto, BigDecimal totalConfirmadoHastaPago, BigDecimal saldoPosteriorPago,
            BigDecimal totalPagadoActual, BigDecimal saldoPendienteActual, BigDecimal saldoPendiente
    ) {}

    @Schema(name="PaymentCreatedResponse")
    public record Created(Long pagoSocioId) {}
}
