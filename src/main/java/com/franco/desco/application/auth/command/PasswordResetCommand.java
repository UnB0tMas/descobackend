package com.franco.desco.application.auth.command;

public record PasswordResetCommand(
        String nombreUsuario,
        String codigo,
        String nuevoPassword,
        String confirmarPassword
) {
}
