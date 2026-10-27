package com.franco.desco.application.auth.command;

import java.util.UUID;

public record RequestTwoFactorCommand(
        Long usuarioId,
        UUID correlacionId
) {
}
