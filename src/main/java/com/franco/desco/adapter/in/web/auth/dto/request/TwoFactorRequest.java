package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

@Schema(
        name = "TwoFactorRequest",
        description = "Solicitud de emisión o reemisión de código de segundo factor."
)
public record TwoFactorRequest(

        @Schema(
                description = "Identificador interno del usuario entregado por el flujo de autenticación.",
                example = "25"
        )
        @NotNull(
                message = "La solicitud de verificación no es válida."
        )
        Long usuarioId,

        @Schema(
                description = "Correlación del proceso de autenticación iniciado previamente.",
                example = "ba39b415-8a53-4d35-9a21-384cb0a8eb05",
                format = "uuid"
        )
        @NotNull(
                message = "La solicitud de verificación no es válida."
        )
        UUID correlacionId
) {
}
