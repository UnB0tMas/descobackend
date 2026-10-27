package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(
        name = "PasswordResetRequest",
        description = "Restablecimiento de contraseña utilizando un código de recuperación válido."
)
public record PasswordResetRequest(

        @Schema(
                description = "Nombre de usuario de la cuenta.",
                example = "jfranco",
                maxLength = 80
        )
        @NotBlank(
                message = "Ingrese su nombre de usuario."
        )
        @Size(
                max = 80,
                message = "El nombre de usuario no es válido."
        )
        String nombreUsuario,

        @Schema(
                description = "Código de recuperación recibido por correo.",
                example = "483921",
                pattern = "\\d{6,8}",
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Ingrese el código de recuperación."
        )
        @Pattern(
                regexp = "\\d{6,8}",
                message = "El código de recuperación no es válido."
        )
        String codigo,

        @Schema(
                description = "Nueva contraseña. Se procesa con Argon2id en el backend.",
                example = "************",
                format = "password",
                minLength = 12,
                maxLength = 128,
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Ingrese la nueva contraseña."
        )
        @Size(
                min = 12,
                max = 128,
                message = "La contraseña debe tener entre 12 y 128 caracteres."
        )
        String nuevoPassword,

        @Schema(
                description = "Confirmación de la nueva contraseña.",
                example = "************",
                format = "password",
                minLength = 12,
                maxLength = 128,
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Confirme la nueva contraseña."
        )
        @Size(
                min = 12,
                max = 128,
                message = "La contraseña debe tener entre 12 y 128 caracteres."
        )
        String confirmarPassword
) {
}
