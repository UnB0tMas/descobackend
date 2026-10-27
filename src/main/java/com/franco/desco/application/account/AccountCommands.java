package com.franco.desco.application.account;

import java.util.UUID;

public final class AccountCommands {
    private AccountCommands() {}

    public record CloseSession(UUID sesionObjetivoPublicaId) {}
    public record DeviceRecognition(Long dispositivoUsuarioId, boolean reconocer) {}
    public record ChangePassword(String passwordActual, String nuevoPassword, String confirmarPassword) {}
    public record RequestEmailChange(String nuevoCorreo) {}
    public record ConfirmEmailChange(String codigo) {}
}
