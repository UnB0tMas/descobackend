package com.franco.desco.adapter.in.web.incident;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class IncidentRequests {
    private IncidentRequests() {}

    @Schema(name="IncidentCreateRequest")
    public record Create(
            @NotNull Long operativoVentaId,
            Long entregaSocioId,
            @NotBlank @Size(max=25) String tipoIncidencia,
            @PositiveOrZero BigDecimal pesoAfectadoKg,
            @NotBlank @Size(max=10) String severidad,
            @NotBlank @Size(max=500) String descripcion
    ) {}

    @Schema(name="IncidentReviewRequest")
    public record Review(
            @PositiveOrZero BigDecimal pesoAfectadoKg,
            @NotBlank @Size(max=10) String severidad,
            @NotBlank @Size(max=500) String descripcion
    ) {}

    @Schema(name="IncidentResolveRequest")
    public record Resolve(@NotBlank @Size(max=500) String motivo) {}

    @Schema(name="IncidentCancelRequest")
    public record Cancel(@NotBlank @Size(max=500) String motivo) {}
}
