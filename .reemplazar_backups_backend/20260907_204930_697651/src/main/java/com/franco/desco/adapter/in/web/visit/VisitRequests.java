package com.franco.desco.adapter.in.web.visit;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public final class VisitRequests {

    private VisitRequests() {
    }

    @Schema(name = "VisitStartRequest")
    public record Start(
            @NotNull @Positive Long salidaParticipanteId,
            @NotNull @Positive Long predioId,
            @NotNull @PastOrPresent Instant fechaHoraInicio,
            @NotNull
            @DecimalMin("-90.0")
            @DecimalMax("90.0")
            BigDecimal latitud,
            @NotNull
            @DecimalMin("-180.0")
            @DecimalMax("180.0")
            BigDecimal longitud,
            @NotBlank @Size(max = 250) String objetivo
    ) {
    }

    @Schema(name = "VisitUpdateRequest")
    public record Update(
            @NotBlank @Size(max = 250) String objetivo,
            @Size(max = 600) String resumen,
            @Size(max = 600) String recomendaciones
    ) {
    }

    @Schema(name = "VisitFinishRequest")
    public record Finish(
            @NotNull @PastOrPresent Instant fechaHoraFin,
            @NotBlank @Size(max = 600) String resumen,
            @NotBlank @Size(max = 600) String recomendaciones
    ) {
    }

    @Schema(name = "VisitAnnulRequest")
    public record Annul(
            @NotBlank @Size(max = 500) String motivo,
            @NotNull @PastOrPresent Instant fechaHoraFin
    ) {
    }
}
