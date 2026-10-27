package com.franco.desco.adapter.in.web.production;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public final class ProductionRequests {

    private ProductionRequests() {
    }

    @Schema(name = "ProductionCreateRequest")
    public record Create(
            @NotNull @Positive Long parcelaCultivoId,
            @NotNull @Positive Long visitaTecnicaId,
            @NotNull @PastOrPresent Instant fechaEstimacion,
            @NotNull LocalDate disponibleDesde,
            @NotNull LocalDate disponibleHasta,
            @NotNull
            @Positive
            @Digits(integer = 11, fraction = 3)
            BigDecimal cantidadEstimadaKg,
            @Size(max = 400) String observacion
    ) {
        @AssertTrue(message = "El rango de disponibilidad no es válido.")
        public boolean rangoDisponibilidadValido() {
            return disponibleDesde == null
                    || disponibleHasta == null
                    || !disponibleHasta.isBefore(disponibleDesde);
        }
    }

    @Schema(name = "ProductionUpdateRequest")
    public record Update(
            @NotNull LocalDate disponibleDesde,
            @NotNull LocalDate disponibleHasta,
            @NotNull
            @Positive
            @Digits(integer = 11, fraction = 3)
            BigDecimal cantidadEstimadaKg,
            @Size(max = 400) String observacion
    ) {
        @AssertTrue(message = "El rango de disponibilidad no es válido.")
        public boolean rangoDisponibilidadValido() {
            return disponibleDesde == null
                    || disponibleHasta == null
                    || !disponibleHasta.isBefore(disponibleDesde);
        }
    }

    @Schema(name = "ProductionDiscardRequest")
    public record Discard(
            @NotBlank @Size(max = 500) String motivo
    ) {
    }
}
