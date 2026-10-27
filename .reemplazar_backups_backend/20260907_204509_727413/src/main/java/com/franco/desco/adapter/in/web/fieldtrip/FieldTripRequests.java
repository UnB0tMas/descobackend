package com.franco.desco.adapter.in.web.fieldtrip;import io.swagger.v3.oas.annotations.media.Schema;import jakarta.validation.Valid;import jakarta.validation.constraints.*;import java.time.Instant;import java.util.List;
public final class FieldTripRequests{private FieldTripRequests(){}@Schema(name="FieldTripParticipantRequest")public record Participant(@NotNull Long empleadoId,@Size(max=120)String funcion,boolean esResponsable){}
 @Schema(name="FieldTripProgramRequest")public record Program(@NotNull Integer motivoSalidaId,@NotNull Instant fechaHoraProgramada,@Size(max=400)String descripcion,@NotEmpty List<@Valid Participant> participantes){}
 @Schema(name="FieldTripUpdateRequest")public record Update(@NotNull Integer motivoSalidaId,@NotNull Instant fechaHoraProgramada,@Size(max=400)String descripcion,@NotEmpty List<@Valid Participant> participantes){}
 @Schema(name="FieldTripCancelRequest")public record Cancel(@NotBlank@Size(max=500)String motivo){}@Schema(name="FieldTripFinishRequest")public record Finish(@NotNull Instant fechaHoraRetornoReal,@Size(max=500)String motivo){}
}
