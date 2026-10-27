package com.franco.desco.adapter.in.web.resourceprogram;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public final class ResourceProgramRequests {

    private ResourceProgramRequests() {
    }

    @Schema(name = "ResourceProgramProgramRequest")
    public record Program(
            Long campaniaVentaId,
            Long operativoVentaId,
            Long salidaCampoId,
            Long bienInventarioId,
            Long suministroId,
            @NotNull @Positive BigDecimal cantidadProgramada,
            @Size(max = 300) String observacion
    ) {
    }

    @Schema(name = "ResourceProgramUpdateRequest")
    public record Update(
            @NotNull @Positive BigDecimal cantidadProgramada,
            @Size(max = 300) String observacion
    ) {
    }

    @Schema(name = "ResourceProgramReturnResourceRequest")
    public record ReturnResource(
            @NotNull @Positive BigDecimal cantidadDevuelta,
            @Size(max = 300) String observacion
    ) {
    }

    @Schema(name = "ResourceProgramConsumeRequest")
    public record Consume(
            @Positive BigDecimal cantidadConsumida,
            @Size(max = 300) String observacion
    ) {
    }

    @Schema(name = "ResourceProgramCancelRequest")
    public record Cancel(
            @NotBlank @Size(max = 300) String motivo
    ) {
    }
}
