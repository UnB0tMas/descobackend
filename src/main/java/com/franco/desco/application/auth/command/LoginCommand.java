package com.franco.desco.application.auth.command;

public record LoginCommand(
        String nombreUsuario,
        String password
) {
}
