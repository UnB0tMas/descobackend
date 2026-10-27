package com.franco.desco.application.shared;

import java.util.UUID;

public record SessionIdentity(
        Long usuarioId,
        UUID sesionPublicaId,
        Integer tokenVersion,
        String jti
) {
}
