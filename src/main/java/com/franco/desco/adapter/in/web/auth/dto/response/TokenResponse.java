package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(
        name = "TokenResponse",
        description = "Tokens emitidos para una sesión autenticada."
)
public record TokenResponse(

        @Schema(
                description = "Access token JWT.",
                example = "eyJhbGciOiJIUzUxMiJ9...",
                accessMode = Schema.AccessMode.READ_ONLY
        )
        String accessToken,

        @Schema(
                description = "Tipo de token utilizado en Authorization.",
                example = "Bearer"
        )
        String tokenType,

        @Schema(
                description = "Fecha y hora UTC de expiración del access token.",
                example = "2026-08-29T18:45:00Z",
                format = "date-time"
        )
        Instant accessTokenExpiraUtc,

        @Schema(
                description = "Refresh token rotativo. Debe protegerse en el cliente.",
                example = "QjQ5YWJmY2M...",
                accessMode = Schema.AccessMode.READ_ONLY
        )
        String refreshToken,

        @Schema(
                description = "Fecha y hora UTC de expiración del refresh token.",
                example = "2026-09-05T18:30:00Z",
                format = "date-time"
        )
        Instant refreshTokenExpiraUtc,

        @Schema(
                description = "Identificador público de la sesión.",
                example = "d74df7ad-41b1-4c37-bba8-1d6153952d40",
                format = "uuid"
        )
        UUID sesionPublicaId
) {
}
