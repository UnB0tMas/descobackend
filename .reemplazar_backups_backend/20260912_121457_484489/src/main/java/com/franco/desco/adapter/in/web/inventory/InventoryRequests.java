package com.franco.desco.adapter.in.web.inventory;
import io.swagger.v3.oas.annotations.media.Schema;import jakarta.validation.constraints.*;import java.math.BigDecimal;
public final class InventoryRequests{private InventoryRequests(){}
 @Schema(name="InventoryAssetCreateRequest") public record CreateAsset(@NotNull Long empresaId,@NotNull Long tipoBienId,@NotBlank@Size(max=80)String codigoPatrimonial,@NotBlank@Size(max=150)String nombre,@Size(max=80)String marca,@Size(max=80)String modelo,@Size(max=100)String serie){}
 @Schema(name="InventoryAssetUpdateRequest") public record UpdateAsset(@NotBlank@Size(max=150)String nombre,@Size(max=80)String marca,@Size(max=80)String modelo,@Size(max=100)String serie,@NotBlank@Size(max=20)String estadoBien){}
 public record RetireAsset(@NotBlank@Size(max=500)String motivo){}
 public record RegisterVehicle(@NotBlank@Size(max=20)String placa,@NotBlank@Size(max=40)String tipoVehiculo,@NotNull@PositiveOrZero BigDecimal kilometrajeKm){}
 public record UpdateMileage(@NotNull@PositiveOrZero BigDecimal kilometrajeKm){}
 public record CreateSupply(@NotBlank@Size(max=50)String codigo,@NotBlank@Size(max=150)String nombre,@NotBlank@Size(max=30)String unidadMedida,@NotNull@PositiveOrZero BigDecimal stockInicial){}
 public record UpdateSupply(@NotBlank@Size(max=150)String nombre,@NotBlank@Size(max=30)String unidadMedida){}
 public record AdjustSupply(@NotBlank@Size(max=30)String tipoMovimiento,@NotNull@Positive BigDecimal cantidad,@Size(max=100)String documentoReferencia,@Size(max=500)String observacion){}
}
