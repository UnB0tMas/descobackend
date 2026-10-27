package com.franco.desco.application.account.service;

import com.franco.desco.application.account.AccountCommands.*;
import com.franco.desco.application.account.port.in.AccountUseCase;
import com.franco.desco.application.account.port.out.AccountPersistencePort;
import com.franco.desco.application.auth.port.out.OtpPort;
import com.franco.desco.application.auth.port.out.PasswordHashPort;
import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.application.auth.port.out.SecurityNotificationPort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.account.AccountModels;

import java.util.List;
import java.util.Objects;

public final class AccountApplicationService implements AccountUseCase {

    private final AccountPersistencePort persistence;
    private final PasswordHashPort passwordHash;
    private final OtpPort otp;
    private final SecurityMailPort mail;
    private final SecurityNotificationPort notifications;

    public AccountApplicationService(
            AccountPersistencePort persistence,
            PasswordHashPort passwordHash,
            OtpPort otp,
            SecurityMailPort mail,
            SecurityNotificationPort notifications
    ) {
        this.persistence = persistence;
        this.passwordHash = passwordHash;
        this.otp = otp;
        this.mail = mail;
        this.notifications = notifications;
    }

    @Override
    public AppResult<List<AccountModels.SessionInfo>> sessions(SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(
                persistence.sessions(identity, metadata),
                "SESIONES_LISTADAS",
                "SESIONES_NO_LISTADAS",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> closeSession(CloseSession command, SessionIdentity identity, RequestMetadata metadata) {
        if (command.sesionObjetivoPublicaId() == null) {
            return AppResult.error(AppStatus.BAD_REQUEST, "SESION_NO_VALIDA", "Seleccione la sesión que desea cerrar.");
        }
        return ApplicationResults.ok(
                persistence.closeSession(identity, metadata, command.sesionObjetivoPublicaId()),
                "SESION_CERRADA",
                "SESION_NO_CERRADA",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> closeOtherSessions(SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(
                persistence.closeOtherSessions(identity, metadata),
                "OTRAS_SESIONES_CERRADAS",
                "SESIONES_NO_CERRADAS",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<AccountModels.DeviceInfo>> devices(SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(
                persistence.devices(identity, metadata),
                "DISPOSITIVOS_LISTADOS",
                "DISPOSITIVOS_NO_LISTADOS",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> recognizeDevice(DeviceRecognition command, SessionIdentity identity, RequestMetadata metadata) {
        if (command.dispositivoUsuarioId() == null) {
            return AppResult.error(AppStatus.BAD_REQUEST, "DISPOSITIVO_NO_VALIDO", "Seleccione un dispositivo válido.");
        }
        String action = command.reconocer() ? "RECONOCER" : "QUITAR";
        return ApplicationResults.ok(
                persistence.recognizeDevice(identity, metadata, command.dispositivoUsuarioId(), action),
                command.reconocer() ? "DISPOSITIVO_RECONOCIDO" : "RECONOCIMIENTO_RETIRADO",
                "DISPOSITIVO_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> changePassword(ChangePassword command, SessionIdentity identity, RequestMetadata metadata) {
        if (!Objects.equals(command.nuevoPassword(), command.confirmarPassword())) {
            return AppResult.error(AppStatus.BAD_REQUEST, "PASSWORD_NO_COINCIDE", "Las contraseñas ingresadas no coinciden.");
        }
        if (command.nuevoPassword() == null || command.nuevoPassword().length() < 12) {
            return AppResult.error(AppStatus.BAD_REQUEST, "PASSWORD_NO_VALIDO", "La nueva contraseña debe tener al menos 12 caracteres.");
        }

        PersistenceResult<String> current = persistence.currentPasswordHash(identity, metadata);
        if (!current.exitoso() || current.datos() == null || !passwordHash.matches(command.passwordActual(), current.datos())) {
            return AppResult.error(AppStatus.BAD_REQUEST, "PASSWORD_ACTUAL_NO_VALIDO", "La contraseña actual no es válida.");
        }

        String newHash = passwordHash.encode(command.nuevoPassword());
        return ApplicationResults.ok(
                persistence.changePassword(identity, metadata, newHash),
                "PASSWORD_ACTUALIZADO",
                "PASSWORD_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> requestEmailChange(RequestEmailChange command, SessionIdentity identity, RequestMetadata metadata) {
        if (command.nuevoCorreo() == null || command.nuevoCorreo().isBlank()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CORREO_NO_VALIDO", "Ingrese el nuevo correo de seguridad.");
        }

        OtpPort.GeneratedOtp generated = otp.generate();
        PersistenceResult<AccountModels.EmailChangeIssue> result = persistence.requestEmailChange(
                identity,
                metadata,
                command.nuevoCorreo().trim(),
                generated.hmacHex()
        );

        if (!result.exitoso()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CAMBIO_CORREO_NO_SOLICITADO", result.mensaje());
        }

        AccountModels.EmailChangeIssue issue = result.datos();
        if (issue != null && issue.debeEnviar() && issue.correoDestino() != null) {
            try {
                mail.sendEmailChangeCode(issue.correoDestino(), generated.code());
                if (issue.notificacionSeguridadId() != null) {
                    notifications.markResult(issue.notificacionSeguridadId(), "ENVIADO", null);
                }
            } catch (RuntimeException exception) {
                if (issue.notificacionSeguridadId() != null) {
                    notifications.markResult(issue.notificacionSeguridadId(), "FALLIDO", null);
                }
                return AppResult.error(
                        AppStatus.SERVICE_UNAVAILABLE,
                        "CORREO_NO_DISPONIBLE",
                        "La solicitud fue registrada, pero no fue posible enviar el código. Solicite uno nuevo."
                );
            }
        }

        return AppResult.ok("CAMBIO_CORREO_SOLICITADO", result.mensaje(), null);
    }

    @Override
    public AppResult<Void> confirmEmailChange(ConfirmEmailChange command, SessionIdentity identity, RequestMetadata metadata) {
        if (command.codigo() == null || command.codigo().isBlank()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CODIGO_NO_VALIDO", "Ingrese el código de confirmación.");
        }
        return ApplicationResults.ok(
                persistence.confirmEmailChange(identity, metadata, otp.hash(command.codigo())),
                "CORREO_ACTUALIZADO",
                "CORREO_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }
}
