package com.franco.desco.adapter.in.web.fieldtrip;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;

public final class SalidaDocumentalWebTypes {
    private SalidaDocumentalWebTypes() {}

    public record Solicitud(
            @NotBlank @Size(max=180) String nombre,
            @NotNull @Positive Integer motivoSalidaId,
            @NotNull Instant fechaInicioPrevista,
            @NotNull Instant fechaFinPrevista,
            @Size(max=400) String descripcion,
            @NotEmpty @Valid List<E2WebTypes.DestinoRequest> destinos,
            @Valid List<E2WebTypes.BienRequest> bienes,
            @Valid List<E2WebTypes.ParticipanteRequest> participantes,
            List<@Positive Long> archivoIds
    ) {
        @AssertTrue(message="La fecha final debe ser posterior a la inicial")
        public boolean isFechasValidas() {
            return fechaInicioPrevista!=null && fechaFinPrevista!=null
                   && fechaFinPrevista.isAfter(fechaInicioPrevista);
        }
        @AssertTrue(message="Indique la actividad de cada destino")
        public boolean isDestinosCompletos() {
            return destinos!=null && destinos.stream().allMatch(d -> d.actividadPrevista()!=null
                    && !d.actividadPrevista().isBlank());
        }
    }

    public record Responsable(
            @Positive Long responsableId,
            @NotNull @Positive Long usuarioId,
            @NotBlank @Pattern(regexp="APROBADOR|ENTREGA|INSPECTOR") String funcion,
            @Min(1) @Max(100) Integer prioridad,
            Boolean suplente,
            Boolean activo,
            Instant fechaDesde,
            Instant fechaHasta
    ) {}
}
