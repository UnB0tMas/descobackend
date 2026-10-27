package com.franco.desco.adapter.in.web.resource;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;

public final class ResourceRequests {
    private ResourceRequests() {}

    @Schema(name="ResourceAssetCreateRequest")
    public record CreateAsset(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Integer tipoBienId,
            @NotBlank @Size(max=60) String codigoPatrimonial,
            @NotBlank @Size(max=150) String nombre,
            @Size(max=80) String marca,
            @Size(max=80) String modelo,
            @Size(max=100) String serie,
            @PastOrPresent LocalDate fechaAdquisicion,
            @PositiveOrZero BigDecimal montoAdquisicion,
            @Pattern(regexp="[A-Za-z]{3}") String moneda,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max=500) String observacion
    ) {
        @AssertTrue(message="Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido(){return proveedorPersonaId==null||proveedorEmpresaId==null;}
    }

    @Schema(name="ResourceAssetUpdateRequest")
    public record UpdateAsset(
            @NotNull @Positive Integer tipoBienId,
            @NotBlank @Size(max=150) String nombre,
            @Size(max=80) String marca,
            @Size(max=80) String modelo,
            @Size(max=100) String serie,
            @PastOrPresent LocalDate fechaAdquisicion,
            @PositiveOrZero BigDecimal montoAdquisicion,
            @Pattern(regexp="[A-Za-z]{3}") String moneda,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max=500) String observacion
    ) {
        @AssertTrue(message="Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido(){return proveedorPersonaId==null||proveedorEmpresaId==null;}
    }

    public record ChangeAssetState(
            @NotBlank @Pattern(regexp="DISPONIBLE|ASIGNADO|MANTENIMIENTO|AVERIADO|INACTIVO|BAJA|NO_DISPONIBLE") String estado,
            @Size(max=500) String motivo) {}

    public record Incident(
            @NotBlank @Pattern(regexp="AVERIA|ACCIDENTE|PERDIDA|ROBO|MANTENIMIENTO|OTRO") String tipo,
            @NotNull @PastOrPresent LocalDateTime fechaHora,
            @NotBlank @Size(max=700) String descripcion,
            @PositiveOrZero BigDecimal costoEstimado) {}

    public record CreateProduct(
            @NotNull @Positive Long uotContextoId,
            @NotBlank @Size(max=50) String codigo,
            @NotBlank @Size(max=180) String nombre,
            @Size(max=700) String descripcion,
            @NotBlank @Size(max=20) String unidadMedida,
            @Size(max=100) String categoria) {}

    public record VersionPrice(
            @NotNull @Positive Long uotContextoId,
            @Positive Long uotPrecioId,
            @NotNull @Positive BigDecimal precio,
            @NotBlank @Pattern(regexp="[A-Za-z]{3}") String moneda) {}

    public record CreateWarehouse(
            @NotNull @Positive Long uotId,
            @Positive Long ubicacionId,
            @NotBlank @Size(max=40) String codigo,
            @NotBlank @Size(max=160) String nombre,
            @Size(max=400) String descripcion) {}

    public record ShareWarehouse(@NotNull @Positive Long uotId, boolean permiteEntrada, boolean permiteSalida) {
        @AssertTrue(message="El acceso compartido debe permitir entrada, salida o ambas.")
        public boolean accesoValido(){return permiteEntrada||permiteSalida;}
    }

    public record MovementLine(
            @NotNull @Positive Long productoId,
            @NotNull @Positive BigDecimal cantidad,
            @PositiveOrZero BigDecimal costoUnitario,
            @Pattern(regexp="[A-Za-z]{3}") String moneda,
            @Size(max=80) String lote,
            LocalDate fechaVencimiento) {}

    public record RegisterMovement(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Long almacenId,
            @NotBlank @Pattern(regexp="COMPRA|DONACION|DEVOLUCION|VENTA|CONSUMO|TRANSFERENCIA|AJUSTE|MERMA|OTRO") String tipo,
            @NotBlank @Pattern(regexp="E|S") String naturaleza,
            @NotEmpty List<@Valid MovementLine> detalle,
            @Positive Long proveedorPersonaId,
            @Positive Long proveedorEmpresaId,
            @Size(max=120) String documentoReferencia,
            @Size(max=500) String observacion
    ) {
        @AssertTrue(message="Seleccione solo una persona o una empresa como proveedor.")
        public boolean proveedorValido(){return proveedorPersonaId==null||proveedorEmpresaId==null;}
    }
}
