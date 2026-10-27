package com.franco.desco.domain.auth;

import java.time.Instant;
import java.util.UUID;

public record SessionState(
        Long sesionUsuarioId,
        UUID sesionPublicaId,
        Instant expiracionRenovacionUtc,
        boolean nuevoDispositivo,
        boolean exitoso,
        String mensaje
) {
}
