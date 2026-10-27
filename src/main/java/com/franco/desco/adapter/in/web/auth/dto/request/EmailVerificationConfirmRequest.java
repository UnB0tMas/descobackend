package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

@Schema(
        name = "EmailVerificationConfirmRequest",
        description = "Confirmación del correo de seguridad mediante código de un solo uso."
)
public record EmailVerificationConfirmRequest(

        @Schema(
                description = "Identificador del usuario cuando está disponible en el flujo.",
                example = "25",
                nullable = true
        )
        Long usuarioId,

        @Schema(
                description = "Nombre de usuario cuando el flujo utiliza identificación por username.",
                example = "jfranco",
                maxLength = 80,
                nullable = true
        )
        @Size(
                max = 80,
                message = "El nombre de usuario no es válido."
        )
        String nombreUsuario,

        @Schema(
                description = "Correlación del proceso de verificación cuando fue emitida.",
                example = "ba39b415-8a53-4d35-9a21-384cb0a8eb05",
                format = "uuid",
                nullable = true
        )
        UUID correlacionId,

        @Schema(
                description = "Código de validación recibido por correo.",
                example = "483921",
                pattern = "\\d{6,8}",
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Ingrese el código de validación."
        )
        @Pattern(
                regexp = "\\d{6,8}",
                message = "El código de validación no es válido."
        )
        String codigo
) {
}
