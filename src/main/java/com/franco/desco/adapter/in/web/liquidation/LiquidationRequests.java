package com.franco.desco.adapter.in.web.liquidation;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

public final class LiquidationRequests {
    private LiquidationRequests(){}

    @Schema(name="LiquidationCalculateRequest")
    public record Calculate(@NotNull Long participacionId){}

    @Schema(name="LiquidationRecalculateRequest")
    public record Recalculate(@NotBlank @Size(max=500) String motivo){}

    @Schema(name="LiquidationCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo){}
}
