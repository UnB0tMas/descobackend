package com.franco.desco.adapter.in.web.sanitation;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

public final class SanitationRequests {

    private SanitationRequests() {
    }

    @Schema(name = "SanitationCreateRequest")
    public record Create(
            @NotNull @Positive Long parcelaCultivoId,
            @NotNull @Positive Integer tipoProblemaId,
            @NotNull @Positive Long visitaDeteccionId,
            @NotNull @PastOrPresent Instant fechaDeteccion,
            @PositiveOrZero Integer plantasAfectadas,
            boolean cantidadEstimada,
            @NotBlank
            @Pattern(regexp = "BAJA|MEDIA|ALTA")
            String severidad,
            @Size(max = 500) String observacion
    ) {
    }

    @Schema(name = "SanitationUpdateRequest")
    public record Update(
            @NotNull @Positive Integer tipoProblemaId,
            @PositiveOrZero Integer plantasAfectadas,
            boolean cantidadEstimada,
            @NotBlank
            @Pattern(regexp = "BAJA|MEDIA|ALTA")
            String severidad,
            @Size(max = 500) String observacion
    ) {
    }

    @Schema(name = "SanitationChangeStateRequest")
    public record ChangeState(
            @NotBlank
            @Pattern(regexp = "DETECTADO|EN_TRATAMIENTO|EN_SEGUIMIENTO|CONTROLADO|RECUPERADO|NO_RECUPERADO|CERRADO")
            String nuevoEstado,
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    @Schema(name = "SanitationCloseRequest")
    public record Close(
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    @Schema(name = "SanitationTreatmentRequest")
    public record Treatment(
            @Positive Long visitaTecnicaId,
            @NotNull @Positive Long responsableEmpleadoId,
            @NotNull @PastOrPresent Instant fechaHora,
            @NotBlank @Size(max = 300) String tratamiento,
            @Size(max = 160) String producto,
            @Positive
            @Digits(integer = 8, fraction = 4)
            BigDecimal dosis,
            @Size(max = 30) String unidadDosis,
            @Size(max = 400) String observacion,
            @Positive Long programacionProductoId,
            @Positive @Digits(integer=16,fraction=3) BigDecimal cantidadUtilizada
    ) {
        @AssertTrue(message = "Seleccione el producto entregado y su cantidad utilizada.")
        public boolean isConsumoCompleto() { return (programacionProductoId == null) == (cantidadUtilizada == null); }

        @AssertTrue(message = "La dosis y la unidad deben informarse juntas.")
        public boolean dosisCompleta() {
            boolean hasDose = dosis != null;
            boolean hasUnit = unidadDosis != null && !unidadDosis.isBlank();
            return hasDose == hasUnit;
        }
    }

    @Schema(name = "SanitationFollowUpRequest")
    public record FollowUp(
            @Positive Long visitaTecnicaId,
            @NotNull @PastOrPresent Instant fechaHora,
            @PositiveOrZero Integer plantasAfectadas,
            boolean cantidadEstimada,
            @NotBlank
            @Pattern(regexp = "BAJA|MEDIA|ALTA")
            String severidad,
            @NotBlank
            @Pattern(regexp = "MEJORA|IGUAL|EMPEORA|CONTROLADO|RECUPERADO|NO_RECUPERADO")
            String resultado,
            @Size(max = 500) String observacion
    ) {
    }
}
