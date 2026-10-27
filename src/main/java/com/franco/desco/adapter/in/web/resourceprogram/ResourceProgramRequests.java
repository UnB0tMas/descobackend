package com.franco.desco.adapter.in.web.resourceprogram;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.AssertTrue;
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
        @AssertTrue(message = "Seleccione un único destino para el recurso.")
        public boolean destinoValido() {
            int destinations = 0;
            destinations += campaniaVentaId == null ? 0 : 1;
            destinations += operativoVentaId == null ? 0 : 1;
            destinations += salidaCampoId == null ? 0 : 1;
            return destinations == 1;
        }

        @AssertTrue(message = "Seleccione un único bien o suministro.")
        public boolean recursoValido() {
            int resources = 0;
            resources += bienInventarioId == null ? 0 : 1;
            resources += suministroId == null ? 0 : 1;
            return resources == 1;
        }
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
