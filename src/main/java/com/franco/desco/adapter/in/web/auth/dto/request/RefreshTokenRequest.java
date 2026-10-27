package com.franco.desco.adapter.in.web.auth.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(
        name = "RefreshTokenRequest",
        description = "Solicitud de rotación del refresh token."
)
public record RefreshTokenRequest(

        @Schema(
                description = "Refresh token entregado durante la autenticación o la última renovación.",
                example = "QjQ5YWJmY2M...",
                maxLength = 600,
                accessMode = Schema.AccessMode.WRITE_ONLY
        )
        @NotBlank(
                message = "La sesión de renovación no es válida."
        )
        @Size(
                max = 600,
                message = "La sesión de renovación no es válida."
        )
        String refreshToken
) {
}
