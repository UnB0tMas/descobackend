package com.franco.desco.adapter.in.web.cultivation;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public final class CultivationRequests {

    private CultivationRequests() {
    }

    @Schema(name = "PlotCreateRequest")
    public record CreatePlot(
            @NotNull @Positive Long predioId,
            @NotBlank @Size(max = 120) String nombre,
            @NotNull @Positive @Digits(integer = 6, fraction = 4) BigDecimal areaHa
    ) {
    }

    @Schema(name = "PlotUpdateRequest")
    public record UpdatePlot(
            @NotNull @Positive Long predioId,
            @NotBlank @Size(max = 120) String nombre,
            @NotNull @Positive @Digits(integer = 6, fraction = 4) BigDecimal areaHa
    ) {
    }

    @Schema(name = "CropCreateRequest")
    public record CreateCrop(
            @NotNull @Positive Long parcelaId,
            @NotNull @Positive Long variedadPaltaId,
            @NotNull @PastOrPresent LocalDate fechaInicio
    ) {
    }

    @Schema(name = "CropUpdateRequest")
    public record UpdateCrop(
            @NotNull @Positive Long variedadPaltaId,
            @NotNull @PastOrPresent LocalDate fechaInicio
    ) {
    }

    @Schema(name = "CropFinishRequest")
    public record FinishCrop(
            @NotNull @PastOrPresent LocalDate fechaFin,
            @NotBlank @Size(max = 500) String motivo
    ) {
    }
}
