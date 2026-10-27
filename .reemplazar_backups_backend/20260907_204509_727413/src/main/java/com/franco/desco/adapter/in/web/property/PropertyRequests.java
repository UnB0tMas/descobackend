package com.franco.desco.adapter.in.web.property;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class PropertyRequests {
    private PropertyRequests() {}
    public record Location(@NotBlank @Size(max=12) String distritoCodigo,Long centroPobladoId,@Size(max=500) String referencia,BigDecimal latitud,BigDecimal longitud,BigDecimal altitudM){}
    public record Characteristics(@NotNull @Positive BigDecimal areaTotalHa,@NotNull @PositiveOrZero BigDecimal areaCultivableHa,@NotBlank @Size(max=40) String tipoRiego,@Size(max=150) String fuenteAgua,@Size(max=1000) String infraestructura,@Size(max=1000) String observacion,@NotNull LocalDate fechaDesde){}
    public record Owner(@NotNull Long socioId,@NotBlank @Size(max=30) String tipoTitularidad,@NotNull @DecimalMin("0.01") @DecimalMax("100.00") BigDecimal porcentaje){}
    @Schema(name="PropertyCreateRequest") public record Create(@NotBlank @Size(max=50) String codigo,@NotBlank @Size(max=150) String nombre,@NotNull LocalDate fechaRegistro,@NotNull @Valid Location ubicacion,@NotNull @Valid Characteristics caracteristicas,@NotEmpty List<@Valid Owner> titulares){}
    @Schema(name="PropertyUpdateRequest") public record Update(@NotBlank @Size(max=50) String codigo,@NotBlank @Size(max=150) String nombre,LocalDate fechaTitularidad,@Valid Location ubicacion,@Valid Characteristics caracteristicas,List<@Valid Owner> titulares){}
    @Schema(name="PropertyRetireRequest") public record Retire(@NotNull LocalDate fechaRetiro,@NotBlank @Size(max=500) String motivo){}
}
