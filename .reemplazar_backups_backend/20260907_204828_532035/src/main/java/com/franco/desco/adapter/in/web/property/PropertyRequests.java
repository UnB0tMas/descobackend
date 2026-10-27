package com.franco.desco.adapter.in.web.property;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class PropertyRequests {

    private PropertyRequests() {
    }

    @Schema(name = "PropertyLocationRequest")
    public record Location(
            @NotBlank @Pattern(regexp = "\\d{6}") String distritoCodigo,
            @Positive Long centroPobladoId,
            @Size(max = 300) String referencia,
            @DecimalMin("-90.0") @DecimalMax("90.0")
            @Digits(integer = 3, fraction = 6)
            BigDecimal latitud,
            @DecimalMin("-180.0") @DecimalMax("180.0")
            @Digits(integer = 3, fraction = 6)
            BigDecimal longitud,
            @DecimalMin("-500.00") @DecimalMax("7000.00")
            @Digits(integer = 6, fraction = 2)
            BigDecimal altitudM
    ) {
        @AssertTrue(message = "La latitud y longitud deben informarse juntas.")
        public boolean coordenadasCompletas() {
            return (latitud == null) == (longitud == null);
        }
    }

    @Schema(name = "PropertyCharacteristicsRequest")
    public record Characteristics(
            @NotNull @Positive
            @Digits(integer = 6, fraction = 4)
            BigDecimal areaTotalHa,
            @NotNull @PositiveOrZero
            @Digits(integer = 6, fraction = 4)
            BigDecimal areaCultivableHa,
            @NotBlank @Size(max = 30) String tipoRiego,
            @Size(max = 150) String fuenteAgua,
            @Size(max = 300) String infraestructura,
            @Size(max = 500) String observacion,
            @NotNull @PastOrPresent LocalDate fechaDesde
    ) {
        @AssertTrue(message = "El área cultivable no puede superar el área total.")
        public boolean areasValidas() {
            return areaTotalHa == null
                    || areaCultivableHa == null
                    || areaCultivableHa.compareTo(areaTotalHa) <= 0;
        }
    }

    @Schema(name = "PropertyOwnerRequest")
    public record Owner(
            @NotNull @Positive Long socioId,
            @NotBlank
            @Pattern(regexp = "PROPIETARIO|COPROPIETARIO|POSESIONARIO|ARRENDATARIO|OTRO")
            String tipoTitularidad,
            @NotNull
            @DecimalMin("0.01")
            @DecimalMax("100.00")
            @Digits(integer = 3, fraction = 2)
            BigDecimal porcentaje
    ) {
    }

    @Schema(name = "PropertyCreateRequest")
    public record Create(
            @NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 150) String nombre,
            @NotNull @PastOrPresent LocalDate fechaRegistro,
            @NotNull @Valid Location ubicacion,
            @NotNull @Valid Characteristics caracteristicas,
            @NotEmpty List<@Valid Owner> titulares
    ) {
        @AssertTrue(message = "La vigencia de las características no puede ser anterior al registro del predio.")
        public boolean fechasValidas() {
            return fechaRegistro == null
                    || caracteristicas == null
                    || caracteristicas.fechaDesde() == null
                    || !caracteristicas.fechaDesde().isBefore(fechaRegistro);
        }

        @AssertTrue(message = "La titularidad contiene socios duplicados o supera el 100 %.")
        public boolean titularesValidos() {
            return ownersValid(titulares);
        }
    }

    @Schema(name = "PropertyUpdateRequest")
    public record Update(
            @NotBlank @Size(max = 40) String codigo,
            @NotBlank @Size(max = 150) String nombre,
            @PastOrPresent LocalDate fechaTitularidad,
            @Valid Location ubicacion,
            @Valid Characteristics caracteristicas,
            List<@Valid Owner> titulares
    ) {
        @AssertTrue(message = "La titularidad contiene socios duplicados o supera el 100 %.")
        public boolean titularesValidos() {
            return titulares == null || ownersValid(titulares);
        }
    }

    @Schema(name = "PropertyRetireRequest")
    public record Retire(
            @NotNull @PastOrPresent LocalDate fechaRetiro,
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    private static boolean ownersValid(List<Owner> owners) {
        if (owners == null || owners.isEmpty()) {
            return true;
        }

        Set<Long> ids = new HashSet<>();
        BigDecimal total = BigDecimal.ZERO;

        for (Owner owner : owners) {
            if (owner == null || owner.socioId() == null) {
                continue;
            }

            if (!ids.add(owner.socioId())) {
                return false;
            }

            if (owner.porcentaje() != null) {
                total = total.add(owner.porcentaje());
            }
        }

        return total.compareTo(new BigDecimal("100.00")) <= 0;
    }
}
