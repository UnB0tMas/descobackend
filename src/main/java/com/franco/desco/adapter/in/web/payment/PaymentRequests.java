package com.franco.desco.adapter.in.web.payment;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class PaymentRequests {
    private PaymentRequests() {}

    @Schema(name="PaymentCreateRequest")
    public record Create(
            @NotNull Long liquidacionSocioId,
            @NotNull @DecimalMin(value="0.01") BigDecimal importe,
            @NotBlank @Size(max=60) String medioPago,
            @Size(max=120) String numeroOperacion
    ) {}

    @Schema(name="PaymentCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo) {}
}
