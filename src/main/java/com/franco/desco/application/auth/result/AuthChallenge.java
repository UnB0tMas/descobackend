package com.franco.desco.application.auth.result;

import java.util.UUID;

public record AuthChallenge(
        AuthStep paso,
        Long usuarioId,
        String nombreUsuario,
        UUID correlacionId,
        String correoEnmascarado
) {
}
