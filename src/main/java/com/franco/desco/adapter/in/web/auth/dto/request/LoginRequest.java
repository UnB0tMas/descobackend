package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(
        name = "LoginRequest",
        description = "Credenciales utilizadas para iniciar sesión."
)
public record LoginRequest(

        @Schema(
                description = "Nombre de usuario. El correo no sustituye automáticamente al nombre de usuario.",
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
                description = "Contraseña del usuario.",
                example = "************",
                format = "password",
                maxLength = 128,
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "Ingrese su contraseña."
        )
        @Size(
                max = 128,
                message = "La contraseña no es válida."
        )
        String password
) {
}
