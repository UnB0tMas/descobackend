package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(
        name = "PasswordRecoveryRequest",
        description = "Solicitud de recuperación de contraseña."
)
public record PasswordRecoveryRequest(

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
        String nombreUsuario
) {
}
