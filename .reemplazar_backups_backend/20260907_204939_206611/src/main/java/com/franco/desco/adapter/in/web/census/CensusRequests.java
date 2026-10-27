package com.franco.desco.adapter.in.web.census;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class CensusRequests {

    private CensusRequests() {
    }

    @Schema(name = "CensusCreateRequest")
    public record Create(
            @NotNull @Positive Long parcelaCultivoId,
            @NotNull @PastOrPresent LocalDate fechaCenso,
            @NotNull @PositiveOrZero Integer plantasTotales,
            @NotNull @PositiveOrZero Integer plantasProductivas,
            @NotNull @PositiveOrZero Integer plantasNoProductivas,
            @NotNull @PositiveOrZero Integer plantasNuevas,
            @NotNull @PositiveOrZero Integer plantasMuertas,
            @NotNull @PositiveOrZero Integer plantasAfectadas,
            @Size(max = 300) String observacion
    ) {
        @AssertTrue(message = "Los conteos del censo no son consistentes con el total.")
        public boolean conteosConsistentes() {
            if (plantasTotales == null
                    || plantasProductivas == null
                    || plantasNoProductivas == null
                    || plantasAfectadas == null) {
                return true;
            }

            return plantasProductivas + plantasNoProductivas <= plantasTotales
                    && plantasAfectadas <= plantasTotales;
        }
    }

    @Schema(name = "CensusUpdateRequest")
    public record Update(
            @NotNull @Positive Long parcelaCultivoId,
            @NotNull @PastOrPresent LocalDate fechaCenso,
            @NotNull @PositiveOrZero Integer plantasTotales,
            @NotNull @PositiveOrZero Integer plantasProductivas,
            @NotNull @PositiveOrZero Integer plantasNoProductivas,
            @NotNull @PositiveOrZero Integer plantasNuevas,
            @NotNull @PositiveOrZero Integer plantasMuertas,
            @NotNull @PositiveOrZero Integer plantasAfectadas,
            @Size(max = 300) String observacion
    ) {
        @AssertTrue(message = "Los conteos del censo no son consistentes con el total.")
        public boolean conteosConsistentes() {
            if (plantasTotales == null
                    || plantasProductivas == null
                    || plantasNoProductivas == null
                    || plantasAfectadas == null) {
                return true;
            }

            return plantasProductivas + plantasNoProductivas <= plantasTotales
                    && plantasAfectadas <= plantasTotales;
        }
    }
}
