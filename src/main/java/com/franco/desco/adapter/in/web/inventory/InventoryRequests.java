package com.franco.desco.adapter.in.web.inventory;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public final class InventoryRequests {

    private InventoryRequests() {
    }

    @Schema(name = "InventoryAssetCreateRequest")
    public record CreateAsset(
            @NotNull Long empresaId,
            @NotNull Long tipoBienId,
            @NotBlank @Size(max = 60) String codigoPatrimonial,
            @NotBlank @Size(max = 150) String nombre,
            @Size(max = 80) String marca,
            @Size(max = 80) String modelo,
            @Size(max = 100) String serie
    ) {
    }

    @Schema(name = "InventoryAssetUpdateRequest")
    public record UpdateAsset(
            @NotBlank @Size(max = 150) String nombre,
            @Size(max = 80) String marca,
            @Size(max = 80) String modelo,
            @Size(max = 100) String serie,
            @NotBlank @Size(max = 20) String estadoBien
    ) {
    }

    @Schema(name = "InventoryAssetRetireRequest")
    public record RetireAsset(
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    @Schema(name = "InventoryVehicleRegisterRequest")
    public record RegisterVehicle(
            @NotBlank @Size(max = 12) String placa,
            @Schema(description = "Código del catálogo TIPO_VEHICULO.")
            @NotBlank @Size(max = 30) String tipoVehiculo,
            @NotNull @PositiveOrZero BigDecimal kilometrajeKm
    ) {
    }

    @Schema(name = "InventoryMileageUpdateRequest")
    public record UpdateMileage(
            @NotNull @PositiveOrZero BigDecimal kilometrajeKm
    ) {
    }

    @Schema(name = "InventorySupplyCreateRequest")
    public record CreateSupply(
            @NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 150) String nombre,
            @Schema(description = "Código del catálogo UNIDAD_MEDIDA.")
            @NotBlank @Size(max = 20) String unidadMedida,
            @NotNull @PositiveOrZero BigDecimal stockInicial
    ) {
    }

    @Schema(name = "InventorySupplyUpdateRequest")
    public record UpdateSupply(
            @NotBlank @Size(max = 150) String nombre,
            @Schema(description = "Código del catálogo UNIDAD_MEDIDA.")
            @NotBlank @Size(max = 20) String unidadMedida
    ) {
    }

    @Schema(name = "InventorySupplyMovementRequest")
    public record AdjustSupply(
            @NotBlank @Size(max = 30) String tipoMovimiento,
            @NotNull @Positive BigDecimal cantidad,
            @Size(max = 100) String documentoReferencia,
            @Size(max = 500) String observacion
    ) {
    }

    @Schema(name = "InventorySupplyMovementAnnulRequest")
    public record AnnulSupplyMovement(
            @NotBlank @Size(max = 300) String motivo
    ) {
    }
}
