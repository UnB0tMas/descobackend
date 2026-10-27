package com.franco.desco.adapter.in.web.evaluation;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public final class EvaluationRequests {

    private EvaluationRequests() {
    }

    @Schema(name = "EvaluationDryMatterRequest")
    public record DryMatter(
            @NotNull
            @DecimalMin("0.0")
            @DecimalMax("100.0")
            @Digits(integer = 3, fraction = 2)
            BigDecimal porcentajeMateriaSeca,

            @NotNull
            @Positive
            Integer numeroMuestras
    ) {
    }

    @Schema(name = "EvaluationCreateRequest")
    public record Create(
            @NotNull @Positive Long visitaTecnicaId,
            @Positive Long parcelaCultivoId,
            @NotNull @Positive Integer tipoEvaluacionId,
            @NotNull @PastOrPresent Instant fechaHora,
            @NotBlank @Size(max = 600) String resultado,
            @Size(max = 400) String observacion,
            @Valid DryMatter materiaSeca
    ) {
    }

    @Schema(name = "EvaluationUpdateRequest")
    public record Update(
            @Positive Long parcelaCultivoId,
            @NotNull @Positive Integer tipoEvaluacionId,
            @NotNull @PastOrPresent Instant fechaHora,
            @NotBlank @Size(max = 600) String resultado,
            @Size(max = 400) String observacion,
            @Valid DryMatter materiaSeca
    ) {
    }

    @Schema(name = "EvaluationRegisterDryMatterRequest")
    public record RegisterDryMatter(
            @NotNull
            @DecimalMin("0.0")
            @DecimalMax("100.0")
            @Digits(integer = 3, fraction = 2)
            BigDecimal porcentajeMateriaSeca,

            @NotNull
            @Positive
            Integer numeroMuestras
    ) {
    }
}
