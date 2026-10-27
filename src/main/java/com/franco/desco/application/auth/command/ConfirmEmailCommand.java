package com.franco.desco.application.auth.command;

import java.util.UUID;

public record ConfirmEmailCommand(
        Long usuarioId,
        String nombreUsuario,
        String codigo,
        UUID correlacionId
) {
}
