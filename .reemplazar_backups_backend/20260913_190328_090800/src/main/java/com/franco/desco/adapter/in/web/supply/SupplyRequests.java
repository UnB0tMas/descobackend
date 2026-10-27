package com.franco.desco.adapter.in.web.supply;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class SupplyRequests {
    private SupplyRequests() {}
    @Schema(name="SupplyCreateRequest")
    public record Create(@NotNull @Positive Long uotId,@NotBlank @Size(max=40) String codigo,@NotBlank @Size(max=150) String nombre,@NotBlank @Size(max=20) String unidadMedida,@NotNull @PositiveOrZero BigDecimal stockInicial,@PositiveOrZero BigDecimal stockMinimo){}
    @Schema(name="SupplyUpdateRequest")
    public record Update(@NotNull @Positive Long uotId,@NotBlank @Size(max=150) String nombre,@NotBlank @Size(max=20) String unidadMedida,@PositiveOrZero BigDecimal stockMinimo){}
    @Schema(name="SupplyMovementCreateRequest")
    public record Movement(@NotNull @Positive Long uotId,@NotBlank @Pattern(regexp="ENTRADA|AJUSTE_ENTRADA|AJUSTE_SALIDA") String tipoMovimiento,@NotNull @Positive BigDecimal cantidad,@Size(max=120) String documentoReferencia,@Size(max=300) String observacion){}
    @Schema(name="SupplyMovementCancelRequest")
    public record CancelMovement(@NotNull @Positive Long uotId,@NotBlank @Size(max=300) String motivo){}
}
