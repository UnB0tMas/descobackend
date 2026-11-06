package com.franco.desco.adapter.in.web.supply;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public final class SupplyRequests {

    private SupplyRequests() {
    }

    @Schema(name = "SupplyCreateRequest")
    public record Create(
            @NotNull @Positive Long uotId,
            @Schema(description = "Código del suministro. Si se omite o queda vacío, DESCO genera uno sugerido para la UOT.")
            @Size(max = 40) String codigo,
            @NotBlank @Size(max = 150) String nombre,
            @Schema(description = "Código del catálogo UNIDAD_MEDIDA.")
            @NotBlank @Size(max = 20) String unidadMedida,
            @NotNull @PositiveOrZero @Digits(integer = 11, fraction = 3) BigDecimal stockInicial,
            @PositiveOrZero @Digits(integer = 11, fraction = 3) BigDecimal stockMinimo
    ) {
    }

    @Schema(name = "SupplyUpdateRequest")
    public record Update(
            @NotNull @Positive Long uotId,
            @NotBlank @Size(max = 150) String nombre,
            @Schema(description = "Código del catálogo UNIDAD_MEDIDA.")
            @NotBlank @Size(max = 20) String unidadMedida,
            @PositiveOrZero @Digits(integer = 11, fraction = 3) BigDecimal stockMinimo
    ) {
    }

    @Schema(name = "SupplyMovementCreateRequest")
    public record Movement(
            @NotNull @Positive Long uotId,
            @NotBlank
            @Pattern(regexp = "ENTRADA|AJUSTE_ENTRADA|AJUSTE_SALIDA")
            String tipoMovimiento,
            @NotNull @Positive @Digits(integer = 11, fraction = 3) BigDecimal cantidad,
            @Size(max = 120) String documentoReferencia,
            @Size(max = 300) String observacion
    ) {
    }

    @Schema(name = "SupplyMovementCancelRequest")
    public record CancelMovement(
            @NotNull @Positive Long uotId,
            @NotBlank @Size(max = 300) String motivo
    ) {
    }
}
