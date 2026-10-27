package com.franco.desco.application.auth.result;

import java.time.Instant;
import java.util.UUID;

public record TokenSet(
        String accessToken,
        String tokenType,
        Instant accessTokenExpiraUtc,
        String refreshToken,
        Instant refreshTokenExpiraUtc,
        UUID sesionPublicaId
) {
}
