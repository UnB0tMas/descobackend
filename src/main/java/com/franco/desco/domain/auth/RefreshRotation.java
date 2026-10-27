package com.franco.desco.domain.auth;

import java.time.Instant;

public record RefreshRotation(
        Long usuarioId,
        Integer tokenVersion,
        Instant expiracionRenovacionUtc,
        boolean exitoso,
        String mensaje
) {
}
