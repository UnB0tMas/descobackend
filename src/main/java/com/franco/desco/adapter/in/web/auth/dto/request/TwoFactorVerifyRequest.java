package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

@Schema(
        name = "TwoFactorVerifyRequest",
        description = "Código de segundo factor asociado al proceso de autenticación."
)
public record TwoFactorVerifyRequest(

        @Schema(
                description = "Identificador interno del usuario.",
                example = "25"
        )
        @NotNull(
                message = "La solicitud de verificación no es válida."
        )
        Long usuarioId,

        @Schema(
                description = "Correlación del proceso de autenticación.",
                example = "ba39b415-8a53-4d35-9a21-384cb0a8eb05",
                format = "uuid"
        )
        @NotNull(
                message = "La solicitud de verificación no es válida."
        )
        UUID correlacionId,

        @Schema(
                description = "Código de seguridad recibido por correo.",
                example = "483921",
                pattern = "\\d{6,8}",
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Ingrese el código de seguridad."
        )
        @Pattern(
                regexp = "\\d{6,8}",
                message = "El código de seguridad no es válido."
        )
        String codigo
) {
}
