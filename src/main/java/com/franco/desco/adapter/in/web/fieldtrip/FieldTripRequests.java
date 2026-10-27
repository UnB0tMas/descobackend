package com.franco.desco.adapter.in.web.fieldtrip;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class FieldTripRequests {

    private FieldTripRequests() {
    }

    @Schema(name = "FieldTripParticipantRequest")
    public record Participant(
            @NotNull @Positive Long empleadoId,
            @Size(max = 120) String funcion,
            boolean esResponsable
    ) {
    }

    @Schema(name = "FieldTripProgramRequest")
    public record Program(
            @NotNull @Positive Integer motivoSalidaId,
            @NotNull @FutureOrPresent Instant fechaHoraProgramada,
            @Size(max = 400) String descripcion,
            @NotEmpty List<@Valid Participant> participantes
    ) {
        @AssertTrue(message = "Debe existir exactamente un responsable y no se pueden repetir participantes.")
        public boolean participantesValidos() {
            return validParticipants(participantes);
        }
    }

    @Schema(name = "FieldTripUpdateRequest")
    public record Update(
            @NotNull @Positive Integer motivoSalidaId,
            @NotNull @FutureOrPresent Instant fechaHoraProgramada,
            @Size(max = 400) String descripcion,
            @NotEmpty List<@Valid Participant> participantes
    ) {
        @AssertTrue(message = "Debe existir exactamente un responsable y no se pueden repetir participantes.")
        public boolean participantesValidos() {
            return validParticipants(participantes);
        }
    }

    @Schema(name = "FieldTripCancelRequest")
    public record Cancel(
            @NotBlank @Size(max = 500) String motivo
    ) {
    }

    @Schema(name = "FieldTripFinishRequest")
    public record Finish(
            @NotNull @PastOrPresent Instant fechaHoraRetornoReal,
            @Size(max = 500) String motivo
    ) {
    }

    private static boolean validParticipants(
            List<Participant> participants
    ) {
        if (participants == null || participants.isEmpty()) {
            return true;
        }

        Set<Long> ids = new HashSet<>();
        int responsibleCount = 0;

        for (Participant participant : participants) {
            if (participant == null || participant.empleadoId() == null) {
                continue;
            }

            if (!ids.add(participant.empleadoId())) {
                return false;
            }

            if (participant.esResponsable()) {
                responsibleCount++;
            }
        }

        return responsibleCount == 1;
    }
}
