package com.franco.desco.adapter.in.web.buyercollection;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class BuyerCollectionRequests {
    private BuyerCollectionRequests() {}

    @Schema(name="BuyerCollectionCreateRequest")
    public record Create(
            @NotNull Long campaniaVentaId,
            Long operativoVentaId,
            @NotNull @DecimalMin(value="0.01") BigDecimal importe,
            @NotBlank @Size(max=10) String moneda,
            @NotBlank @Size(max=60) String medioPago,
            @Size(max=120) String numeroOperacion
    ) {}

    @Schema(name="BuyerCollectionCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo) {}
}
