package com.franco.desco.adapter.in.web.priceadjustment;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class PriceAdjustmentRequests {
    private PriceAdjustmentRequests() {}

    @Schema(name="PriceAdjustmentCreateRequest")
    public record Create(
            @NotNull Long participacionId,
            Long operativoVentaId,
            Long condicionComercialId,
            @NotBlank @Size(max=25) String tipoAjuste,
            @PositiveOrZero BigDecimal precioOriginal,
            @PositiveOrZero BigDecimal precioAplicado,
            BigDecimal montoAjuste,
            @DecimalMin("0.0") @DecimalMax("100.0") BigDecimal porcentajeAjuste,
            @NotBlank @Size(max=400) String motivo
    ) {}

    @Schema(name="PriceAdjustmentCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo) {}
}
