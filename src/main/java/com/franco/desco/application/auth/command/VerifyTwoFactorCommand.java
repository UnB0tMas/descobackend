package com.franco.desco.application.auth.command;

import java.util.UUID;

public record VerifyTwoFactorCommand(
        Long usuarioId,
        String codigo,
        UUID correlacionId
) {
}
