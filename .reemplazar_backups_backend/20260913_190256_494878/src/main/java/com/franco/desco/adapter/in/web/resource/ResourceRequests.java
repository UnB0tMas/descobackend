package com.franco.desco.adapter.in.web.resource;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

public final class ResourceRequests {
    private ResourceRequests() {}

    @Schema(name = "ResourceAssetCreateRequest")
    public record CreateAsset(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Integer tipoBienId,
            @NotBlank @Size(max = 60) String codigoPatrimonial,
            @NotBlank @Size(max = 150) String nombre,
            @Size(max = 80) String marca,
            @Size(max = 80) String modelo,
            @Size(max = 100) String serie,
            @PastOrPresent LocalDate fechaAdquisicion,
            @PositiveOrZero BigDecimal montoAdquisicion,
            @Schema(example = "PEN", minLength = 3, maxLength = 3)
            @Pattern(regexp = "[A-Za-z]{3}") String moneda,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max = 500) String observacion
    ) {
        @AssertTrue(message = "Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido() {
            return proveedorPersonaId == null || proveedorEmpresaId == null;
        }
    }

    @Schema(name = "ResourceAssetUpdateRequest")
    public record UpdateAsset(
            @NotNull @Positive Integer tipoBienId,
            @NotBlank @Size(max = 150) String nombre,
            @Size(max = 80) String marca,
            @Size(max = 80) String modelo,
            @Size(max = 100) String serie,
            @PastOrPresent LocalDate fechaAdquisicion,
            @PositiveOrZero BigDecimal montoAdquisicion,
            @Schema(example = "PEN", minLength = 3, maxLength = 3)
            @Pattern(regexp = "[A-Za-z]{3}") String moneda,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max = 500) String observacion
    ) {
        @AssertTrue(message = "Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido() {
            return proveedorPersonaId == null || proveedorEmpresaId == null;
        }
    }

    @Schema(name = "ResourceAssetStateChangeRequest")
    public record ChangeAssetState(
            @Schema(
                    allowableValues = {"DISPONIBLE", "ASIGNADO", "MANTENIMIENTO", "AVERIADO", "INACTIVO", "BAJA", "NO_DISPONIBLE"},
                    example = "MANTENIMIENTO"
            )
            @NotBlank @Pattern(regexp = "DISPONIBLE|ASIGNADO|MANTENIMIENTO|AVERIADO|INACTIVO|BAJA|NO_DISPONIBLE") String estado,
            @Size(max = 500) String motivo
    ) {}

    @Schema(name = "ResourceAssetIncidentRequest")
    public record Incident(
            @Schema(allowableValues = {"AVERIA", "ACCIDENTE", "PERDIDA", "ROBO", "MANTENIMIENTO", "OTRO"}, example = "AVERIA")
            @NotBlank @Pattern(regexp = "AVERIA|ACCIDENTE|PERDIDA|ROBO|MANTENIMIENTO|OTRO") String tipo,
            @NotNull @PastOrPresent LocalDateTime fechaHora,
            @NotBlank @Size(max = 700) String descripcion,
            @PositiveOrZero BigDecimal costoEstimado
    ) {}

    @Schema(name = "ResourceProductCreateRequest")
    public record CreateProduct(
            @NotNull @Positive Long uotContextoId,
            @NotBlank @Size(max = 50) String codigo,
            @NotBlank @Size(max = 180) String nombre,
            @Size(max = 700) String descripcion,
            @NotBlank @Size(max = 20) String unidadMedida,
            @Size(max = 100) String categoria
    ) {}

    @Schema(name = "ResourceProductPriceVersionRequest")
    public record VersionPrice(
            @NotNull @Positive Long uotContextoId,
            @NotNull @Positive Long uotPrecioId,
            @NotNull @Positive BigDecimal precio,
            @Schema(example = "PEN", minLength = 3, maxLength = 3)
            @NotBlank @Pattern(regexp = "[A-Za-z]{3}") String moneda
    ) {
        @AssertTrue(message = "El precio debe pertenecer a la UOT seleccionada.")
        public boolean mismaUot() {
            return uotContextoId == null || uotPrecioId == null || Objects.equals(uotContextoId, uotPrecioId);
        }
    }

    @Schema(name = "ResourceWarehouseCreateRequest")
    public record CreateWarehouse(
            @NotNull @Positive Long uotId,
            @Positive Long ubicacionId,
            @NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 160) String nombre,
            @Size(max = 400) String descripcion
    ) {}

    @Schema(name = "ResourceWarehouseShareRequest")
    public record ShareWarehouse(
            @NotNull @Positive Long uotId,
            boolean permiteEntrada,
            boolean permiteSalida
    ) {
        @AssertTrue(message = "El acceso compartido debe permitir entrada, salida o ambas.")
        public boolean accesoValido() {
            return permiteEntrada || permiteSalida;
        }
    }

    @Schema(name = "ResourceMovementLineRequest")
    public record MovementLine(
            @NotNull @Positive Long productoId,
            @NotNull @Positive BigDecimal cantidad,
            @PositiveOrZero BigDecimal costoUnitario,
            @Schema(example = "PEN", minLength = 3, maxLength = 3)
            @Pattern(regexp = "[A-Za-z]{3}") String moneda,
            @Size(max = 80) String lote,
            LocalDate fechaVencimiento
    ) {}

    @Schema(name = "ResourceMovementRegisterRequest")
    public record RegisterMovement(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Long almacenId,
            @Schema(allowableValues = {"COMPRA", "DONACION", "DEVOLUCION", "VENTA", "CONSUMO", "TRANSFERENCIA", "AJUSTE", "MERMA", "OTRO"})
            @NotBlank @Pattern(regexp = "COMPRA|DONACION|DEVOLUCION|VENTA|CONSUMO|TRANSFERENCIA|AJUSTE|MERMA|OTRO") String tipo,
            @Schema(allowableValues = {"E", "S"}, description = "Naturaleza del movimiento: E=entrada, S=salida.")
            @NotBlank @Pattern(regexp = "E|S") String naturaleza,
            @NotEmpty List<@Valid MovementLine> detalle,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max = 120) String documentoReferencia,
            @Size(max = 500) String observacion
    ) {
        @AssertTrue(message = "Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido() {
            return proveedorPersonaId == null || proveedorEmpresaId == null;
        }
    }
}
