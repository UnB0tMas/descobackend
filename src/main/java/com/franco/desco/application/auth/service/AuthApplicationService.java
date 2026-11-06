package com.franco.desco.application.auth.service;

import com.franco.desco.application.auth.command.*;
import com.franco.desco.application.auth.port.in.AuthUseCase;
import com.franco.desco.application.auth.port.out.*;
import com.franco.desco.application.auth.result.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.auth.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

public final class AuthApplicationService implements AuthUseCase {

    private static final Logger log =
            LoggerFactory.getLogger(AuthApplicationService.class);

    private static final String GENERIC_LOGIN_MESSAGE =
            "El usuario o la contraseña no son válidos.";

    private static final String GENERIC_RECOVERY_MESSAGE =
            "Si la cuenta está disponible, recibirá instrucciones en su correo de seguridad.";

    private static final String GENERIC_EMAIL_VERIFICATION_MESSAGE =
            "Si la cuenta está disponible, recibirá un código de validación en su correo de seguridad.";

    private final AuthPersistencePort authPersistence;
    private final PasswordHashPort passwordHash;
    private final DeviceFingerprintPort deviceFingerprint;
    private final OtpPort otpPort;
    private final RefreshTokenPort refreshTokenPort;
    private final SecurityMailPort mailPort;
    private final SecurityNotificationPort notificationPort;
    private final AccessTokenPort accessTokenPort;
    private final boolean smtpEnabled;
    private final boolean devAutoVerifyOtp;

    public AuthApplicationService(
            AuthPersistencePort authPersistence,
            PasswordHashPort passwordHash,
            DeviceFingerprintPort deviceFingerprint,
            OtpPort otpPort,
            RefreshTokenPort refreshTokenPort,
            SecurityMailPort mailPort,
            SecurityNotificationPort notificationPort,
            AccessTokenPort accessTokenPort,
            boolean smtpEnabled,
            boolean devAutoVerifyOtp
    ) {
        this.authPersistence = authPersistence;
        this.passwordHash = passwordHash;
        this.deviceFingerprint = deviceFingerprint;
        this.otpPort = otpPort;
        this.refreshTokenPort = refreshTokenPort;
        this.mailPort = mailPort;
        this.notificationPort = notificationPort;
        this.accessTokenPort = accessTokenPort;
        this.smtpEnabled = smtpEnabled;
        this.devAutoVerifyOtp = devAutoVerifyOtp;
    }

    @Override
    public AppResult<LoginResult> login(
            LoginCommand command,
            RequestMetadata metadata
    ) {
        String username = normalizeUsername(command.nombreUsuario());
        String deviceHash = deviceFingerprint.fingerprint(metadata);

        Optional<Credential> credential =
                authPersistence.findCredential(username);

        boolean passwordValid;

        if (credential.isPresent()) {
            passwordValid = safeMatches(
                    command.password(),
                    credential.get().passwordHash()
            );
        } else {
            /*
             * El PA de login establece que el backend debe ejecutar un Argon2
             * dummy cuando el usuario no existe para reducir diferencias de
             * tiempo y evitar enumeración de cuentas.
             */
            safeMatches(command.password(), passwordHash.dummyHash());
            passwordValid = false;
        }

        Long userId = credential
                .map(Credential::usuarioId)
                .orElse(null);

        LoginDecision decision =
                authPersistence.registerCredentialResult(
                        loginDecisionPayload(
                                userId,
                                username,
                                passwordValid,
                                deviceHash,
                                metadata
                        )
                );

        if (!passwordValid || !decision.exitoso()) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "CREDENCIALES_INVALIDAS",
                    GENERIC_LOGIN_MESSAGE
            );
        }

        return switch (safeUpper(decision.pasoSiguiente())) {
            case "VALIDAR_CORREO" ->
                    startEmailVerification(
                            userId,
                            username,
                            metadata.correlacionId(),
                            metadata
                    );

            case "SEGUNDO_FACTOR" ->
                    startTwoFactor(
                            userId,
                            metadata.correlacionId(),
                            metadata
                    );

            case "CREAR_SESION" ->
                    createAuthenticatedSession(
                            userId,
                            metadata.correlacionId(),
                            metadata
                    );

            default ->
                    AppResult.error(
                            AppStatus.UNAUTHORIZED,
                            "LOGIN_NO_DISPONIBLE",
                            "No se pudo iniciar sesión. Intente nuevamente."
                    );
        };
    }

    @Override
    public AppResult<AuthChallenge> requestTwoFactor(
            RequestTwoFactorCommand command,
            RequestMetadata metadata
    ) {
        if (!smtpEnabled) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "SEGUNDO_FACTOR_CORREO_DESHABILITADO",
                    "El reenvío por correo está deshabilitado. Reinicie el inicio de sesión."
            );
        }
        OtpPort.GeneratedOtp otp = otpPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", command.usuarioId());
        payload.put("codigoHmacHex", otp.hmacHex());
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                firstNonNull(
                        command.correlacionId(),
                        metadata.correlacionId()
                )
        );

        OtpIssue issue =
                authPersistence.requestTwoFactor(payload);

        if (!issue.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "SEGUNDO_FACTOR_NO_DISPONIBLE",
                    safeMessage(
                            issue.mensaje(),
                            "No se pudo generar el código de seguridad."
                    )
            );
        }

        if (issue.debeEnviar()
                && !deliverOtp(
                        issue,
                        () -> mailPort.sendTwoFactor(
                                issue.correoDestino(),
                                otp.code()
                        )
                )) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "CORREO_NO_DISPONIBLE",
                    "No se pudo enviar el código de seguridad. Intente nuevamente."
            );
        }

        AuthChallenge challenge = new AuthChallenge(
                AuthStep.TWO_FACTOR_REQUIRED,
                command.usuarioId(),
                null,
                firstNonNull(
                        command.correlacionId(),
                        metadata.correlacionId()
                ),
                maskEmail(issue.correoDestino())
        );

        return AppResult.ok(
                "SEGUNDO_FACTOR_ENVIADO",
                "Revise su correo e ingrese el código de seguridad.",
                challenge
        );
    }

    @Override
    public AppResult<LoginResult> verifyTwoFactor(
            VerifyTwoFactorCommand command,
            RequestMetadata metadata
    ) {
        RefreshTokenPort.PendingRefreshToken refresh =
                refreshTokenPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", command.usuarioId());
        payload.put("codigoHmacHex", otpPort.hash(command.codigo()));
        payload.put(
                "dispositivoHashHex",
                deviceFingerprint.fingerprint(metadata)
        );
        payload.put("refreshTokenHashHex", refresh.hashHex());
        payload.put("navegador", metadata.navegador());
        payload.put("sistemaOperativo", metadata.sistemaOperativo());
        payload.put("userAgent", metadata.userAgent());
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                firstNonNull(
                        command.correlacionId(),
                        metadata.correlacionId()
                )
        );

        SessionState session =
                authPersistence.verifyTwoFactor(payload);

        if (!session.exitoso()
                || session.sesionPublicaId() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "CODIGO_NO_VALIDO",
                    safeMessage(
                            session.mensaje(),
                            "El código ingresado no es válido o ha expirado."
                    )
            );
        }

        return authenticatedResult(
                command.usuarioId(),
                session,
                refresh,
                metadata
        );
    }

    @Override
    public AppResult<Void> requestEmailVerification(
            RequestEmailVerificationCommand command,
            RequestMetadata metadata
    ) {
        // Endpoint público: nunca auto-verificar un correo por nombre de usuario.
        if (!smtpEnabled) {
            return AppResult.ok("VALIDACION_SOLICITADA", GENERIC_EMAIL_VERIFICATION_MESSAGE, null);
        }
        String username = normalizeUsername(command.nombreUsuario());
        OtpPort.GeneratedOtp otp = otpPort.generate();

        Long resolvedUserId = authPersistence
                .findCredential(username)
                .map(Credential::usuarioId)
                .orElse(null);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", resolvedUserId);
        payload.put("nombreUsuario", username);
        payload.put("codigoHmacHex", otp.hmacHex());
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());

        OtpIssue issue =
                authPersistence.requestEmailVerification(payload);

        /*
         * La respuesta pública siempre es general.
         * Nunca se confirma si el usuario existe.
         */
        if (issue.exitoso()
                && issue.debeEnviar()
                && issue.correoDestino() != null
                && resolvedUserId != null) {
            deliverOtp(
                    issue,
                    () -> mailPort.sendEmailVerification(
                            issue.correoDestino(),
                            username,
                            otp.code()
                    )
            );
        }

        return AppResult.ok(
                "VALIDACION_SOLICITADA",
                GENERIC_EMAIL_VERIFICATION_MESSAGE,
                null
        );
    }

    @Override
    public AppResult<Void> confirmEmailVerification(
            ConfirmEmailCommand command,
            RequestMetadata metadata
    ) {
        Long resolvedUserId = command.usuarioId();

        if (resolvedUserId == null
                && command.nombreUsuario() != null
                && !command.nombreUsuario().isBlank()) {
            resolvedUserId = authPersistence
                    .findCredential(
                            normalizeUsername(command.nombreUsuario())
                    )
                    .map(Credential::usuarioId)
                    .orElse(null);
        }

        if (resolvedUserId == null) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "VALIDACION_NO_COMPLETADA",
                    "El código ingresado no es válido o ha expirado."
            );
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", resolvedUserId);
        payload.put("codigoHmacHex", otpPort.hash(command.codigo()));
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                firstNonNull(
                        command.correlacionId(),
                        metadata.correlacionId()
                )
        );

        AuthPersistencePort.ProcedureResult result =
                authPersistence.verifyEmail(payload);

        if (!result.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "VALIDACION_NO_COMPLETADA",
                    safeMessage(
                            result.mensaje(),
                            "El código ingresado no es válido o ha expirado."
                    )
            );
        }

        return AppResult.ok(
                "CORREO_VALIDADO",
                "Correo validado correctamente. Ya puede iniciar sesión.",
                null
        );
    }

    @Override
    public AppResult<Void> requestPasswordRecovery(
            PasswordRecoveryCommand command,
            RequestMetadata metadata
    ) {
        // Mantener respuesta genérica: no emitir OTP recuperables sin canal de entrega.
        if (!smtpEnabled) {
            return AppResult.ok("RECUPERACION_SOLICITADA", GENERIC_RECOVERY_MESSAGE, null);
        }
        String username = normalizeUsername(command.nombreUsuario());

        log.info(
                "[MAIL] Password recovery requested user={}",
                safeLogValue(username)
        );

        /*
         * La recuperación reutiliza la misma resolución de credencial que el
         * login y la validación de correo.
         *
         * La respuesta al cliente continúa siendo genérica para evitar
         * enumeración de usuarios.
         */
        Long resolvedUserId = authPersistence
                .findCredential(username)
                .map(Credential::usuarioId)
                .orElse(null);

        log.debug(
                "[MAIL] Password recovery resolution user={} resolved={} correlationId={}",
                safeLogValue(username),
                resolvedUserId != null,
                metadata.correlacionId()
        );

        OtpPort.GeneratedOtp otp = otpPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", resolvedUserId);
        payload.put("nombreUsuario", username);
        payload.put("codigoHmacHex", otp.hmacHex());
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());

        OtpIssue issue =
                authPersistence.requestPasswordRecovery(payload);

        if (issue == null) {
            log.error(
                    "[MAIL] Password recovery persistence failed user={}",
                    safeLogValue(username)
            );

            return AppResult.ok(
                    "RECUPERACION_SOLICITADA",
                    GENERIC_RECOVERY_MESSAGE,
                    null
            );
        }

        if (!issue.exitoso()) {
            log.warn(
                    "[MAIL] Password recovery not registered user={} reason={}",
                    safeLogValue(username),
                    safeLogValue(issue.mensaje())
            );

            return AppResult.ok(
                    "RECUPERACION_SOLICITADA",
                    GENERIC_RECOVERY_MESSAGE,
                    null
            );
        }

        if (!issue.debeEnviar()) {
            log.info(
                    "[MAIL] Password recovery not dispatched user={} reason={}",
                    safeLogValue(username),
                    safeLogValue(issue.mensaje())
            );

            return AppResult.ok(
                    "RECUPERACION_SOLICITADA",
                    GENERIC_RECOVERY_MESSAGE,
                    null
            );
        }

        if (issue.correoDestino() == null
                || issue.correoDestino().isBlank()) {
            log.error(
                    "[MAIL] Password recovery has no destination user={}",
                    safeLogValue(username)
            );

            return AppResult.ok(
                    "RECUPERACION_SOLICITADA",
                    GENERIC_RECOVERY_MESSAGE,
                    null
            );
        }

        deliverOtp(
                "PASSWORD_RECOVERY",
                metadata.correlacionId(),
                issue,
                () -> mailPort.sendPasswordRecovery(
                        issue.correoDestino(),
                        username,
                        otp.code()
                )
        );

        return AppResult.ok(
                "RECUPERACION_SOLICITADA",
                GENERIC_RECOVERY_MESSAGE,
                null
        );
    }

    @Override
    public AppResult<Void> resetPassword(
            PasswordResetCommand command,
            RequestMetadata metadata
    ) {
        /*
         * Esta comprobación es una validación de contrato porque el password
         * en claro no debe enviarse a SQL Server.
         * Historial, revocación de sesiones y cambio real permanecen en el PA.
         */
        if (!Objects.equals(
                command.nuevoPassword(),
                command.confirmarPassword()
        )) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "PASSWORD_NO_COINCIDE",
                    "Las contraseñas ingresadas no coinciden."
            );
        }

        if (command.nuevoPassword() == null
                || command.nuevoPassword().length() < 12) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "PASSWORD_NO_VALIDO",
                    "La nueva contraseña debe tener al menos 12 caracteres."
            );
        }

        String newPasswordHash =
                passwordHash.encode(command.nuevoPassword());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put(
                "nombreUsuario",
                normalizeUsername(command.nombreUsuario())
        );
        payload.put(
                "codigoHmacHex",
                otpPort.hash(command.codigo())
        );
        payload.put("nuevoPasswordHash", newPasswordHash);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());

        AuthPersistencePort.ProcedureResult result =
                authPersistence.resetPassword(payload);

        if (!result.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "PASSWORD_NO_RESTABLECIDO",
                    safeMessage(
                            result.mensaje(),
                            "El código ingresado no es válido o ha expirado."
                    )
            );
        }

        return AppResult.ok(
                "PASSWORD_RESTABLECIDO",
                "Contraseña actualizada correctamente. Inicie sesión nuevamente.",
                null
        );
    }

    @Override
    public AppResult<RefreshResult> refresh(
            RefreshCommand command,
            RequestMetadata metadata
    ) {
        RefreshTokenPort.ParsedRefreshToken current;

        try {
            current =
                    refreshTokenPort.parse(command.refreshToken());
        } catch (RuntimeException exception) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "REFRESH_TOKEN_INVALIDO",
                    "La sesión de renovación no es válida. Inicie sesión nuevamente."
            );
        }

        RefreshTokenPort.PendingRefreshToken next =
                refreshTokenPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put(
                "sesionPublicaId",
                current.sessionPublicId()
        );
        payload.put(
                "refreshTokenActualHashHex",
                current.hashHex()
        );
        payload.put(
                "refreshTokenNuevoHashHex",
                next.hashHex()
        );
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                metadata.correlacionId()
        );

        RefreshRotation rotation =
                authPersistence.rotateRefresh(payload);

        if (!rotation.exitoso()
                || rotation.usuarioId() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "SESION_NO_RENOVABLE",
                    safeMessage(
                            rotation.mensaje(),
                            "La sesión ya no está disponible. Inicie sesión nuevamente."
                    )
            );
        }

        AuthPersistencePort.AccessContextResult contextResult =
                authPersistence.accessContext(
                        rotation.usuarioId(),
                        current.sessionPublicId()
                );

        if (!contextResult.exitoso()
                || contextResult.contexto() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "SESION_NO_VALIDA",
                    "La sesión ya no está disponible. Inicie sesión nuevamente."
            );
        }

        AccessTokenPort.IssuedAccessToken access =
                accessTokenPort.issue(contextResult.contexto());

        TokenSet tokens = new TokenSet(
                access.token(),
                "Bearer",
                access.expiresAt(),
                refreshTokenPort.compose(
                        current.sessionPublicId(),
                        next.secret()
                ),
                rotation.expiracionRenovacionUtc(),
                current.sessionPublicId()
        );

        return AppResult.ok(
                "SESION_RENOVADA",
                "Sesión renovada correctamente.",
                new RefreshResult(
                        tokens,
                        contextResult.contexto()
                )
        );
    }

    @Override
    public AppResult<AccessContext> me(
            SessionIdentity identity
    ) {
        AuthPersistencePort.AccessContextResult result =
                authPersistence.accessContext(
                        identity.usuarioId(),
                        identity.sesionPublicaId()
                );

        if (!result.exitoso()
                || result.contexto() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "SESION_NO_VALIDA",
                    "Su sesión no está disponible. Inicie sesión nuevamente."
            );
        }

        return AppResult.ok(
                "CONTEXTO_CARGADO",
                "Información de acceso cargada correctamente.",
                result.contexto()
        );
    }

    @Override
    public AppResult<Void> logout(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", identity.usuarioId());
        payload.put(
                "sesionActualPublicaId",
                identity.sesionPublicaId()
        );
        payload.put(
                "sesionObjetivoPublicaId",
                identity.sesionPublicaId()
        );
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                metadata.correlacionId()
        );

        AuthPersistencePort.ProcedureResult result =
                authPersistence.closeSession(payload);

        if (!result.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "SESION_NO_CERRADA",
                    safeMessage(
                            result.mensaje(),
                            "No se pudo cerrar la sesión."
                    )
            );
        }

        return AppResult.ok(
                "SESION_CERRADA",
                "Sesión cerrada correctamente.",
                null
        );
    }

    @Override
    public AppResult<Void> logoutOthers(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", identity.usuarioId());
        payload.put(
                "sesionPublicaId",
                identity.sesionPublicaId()
        );
        payload.put("ip", metadata.ip());
        payload.put(
                "correlacionId",
                metadata.correlacionId()
        );

        AuthPersistencePort.ProcedureResult result =
                authPersistence.closeOtherSessions(payload);

        if (!result.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "SESIONES_NO_CERRADAS",
                    safeMessage(
                            result.mensaje(),
                            "No se pudieron cerrar las demás sesiones."
                    )
            );
        }

        return AppResult.ok(
                "OTRAS_SESIONES_CERRADAS",
                "Las demás sesiones fueron cerradas correctamente.",
                null
        );
    }

    private AppResult<LoginResult> startEmailVerification(
            Long userId,
            String username,
            UUID correlationId,
            RequestMetadata metadata
    ) {
        if (!smtpEnabled && !devAutoVerifyOtp) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,
                    "CORREO_DESHABILITADO", "La verificación de correo requiere un canal de entrega disponible.");
        }
        if (userId == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "LOGIN_NO_DISPONIBLE",
                    GENERIC_LOGIN_MESSAGE
            );
        }

        OtpPort.GeneratedOtp otp = otpPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", userId);
        payload.put("nombreUsuario", username);
        payload.put("codigoHmacHex", otp.hmacHex());
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", correlationId);

        OtpIssue issue =
                authPersistence.requestEmailVerification(payload);

        if (!issue.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "VALIDACION_CORREO_NO_DISPONIBLE",
                    safeMessage(
                            issue.mensaje(),
                            "No se pudo generar la validación de correo."
                    )
            );
        }

        if (!smtpEnabled) {
            // SOLO DESARROLLO, después de una contraseña validada por login().
            // Se valida el hash real contra el PA; jamás se envía OTP al navegador.
            if (!issue.debeEnviar() || issue.codigoUnSoloUsoId() == null) {
                return AppResult.error(AppStatus.BAD_REQUEST,
                        "OTP_DESARROLLO_NO_EMITIDO", "No se pudo emitir un código de validación nuevo.");
            }
            Map<String, Object> verification = new LinkedHashMap<>();
            verification.put("usuarioId", userId);
            verification.put("codigoHmacHex", otp.hmacHex());
            verification.put("ip", metadata.ip());
            verification.put("correlacionId", correlationId);
            AuthPersistencePort.ProcedureResult verified = authPersistence.verifyEmail(verification);
            if (!verified.exitoso()) {
                return AppResult.error(AppStatus.UNAUTHORIZED,
                        "VALIDACION_CORREO_NO_COMPLETADA", "La validación interna no pudo completarse.");
            }
            log.warn("[AUTH] DEV correo validado por PA sin envío SMTP correlationId={}", correlationId);
            // Volver a consultar la decisión del PA: el administrador puede requerir 2FA.
            LoginDecision next = authPersistence.registerCredentialResult(
                    loginDecisionPayload(userId, username, true,
                            deviceFingerprint.fingerprint(metadata), metadata));
            if (!next.exitoso()) {
                return AppResult.error(AppStatus.UNAUTHORIZED,
                        "LOGIN_NO_DISPONIBLE", GENERIC_LOGIN_MESSAGE);
            }
            return switch (safeUpper(next.pasoSiguiente())) {
                case "SEGUNDO_FACTOR" -> startTwoFactor(userId, correlationId, metadata);
                case "CREAR_SESION" -> createAuthenticatedSession(userId, correlationId, metadata);
                default -> AppResult.error(AppStatus.UNAUTHORIZED,
                        "LOGIN_NO_DISPONIBLE", "No se pudo completar la autenticación.");
            };
        }

        if (issue.debeEnviar()
                && !deliverOtp(
                        issue,
                        () -> mailPort.sendEmailVerification(
                                issue.correoDestino(),
                                username,
                                otp.code()
                        )
                )) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "CORREO_NO_DISPONIBLE",
                    "No se pudo enviar el código de validación. Intente nuevamente."
            );
        }

        AuthChallenge challenge = new AuthChallenge(
                AuthStep.EMAIL_VERIFICATION_REQUIRED,
                userId,
                username,
                correlationId,
                maskEmail(issue.correoDestino())
        );

        return AppResult.ok(
                "VALIDACION_CORREO_REQUERIDA",
                "Debe validar su correo de seguridad antes de continuar.",
                new LoginResult(
                        AuthStep.EMAIL_VERIFICATION_REQUIRED,
                        null,
                        null,
                        challenge
                )
        );
    }

    private AppResult<LoginResult> startTwoFactor(
            Long userId,
            UUID correlationId,
            RequestMetadata metadata
    ) {
        if (!smtpEnabled && !devAutoVerifyOtp) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE,
                    "CORREO_DESHABILITADO", "El segundo factor requiere un canal de entrega disponible.");
        }
        if (userId == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "LOGIN_NO_DISPONIBLE",
                    GENERIC_LOGIN_MESSAGE
            );
        }

        OtpPort.GeneratedOtp otp = otpPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", userId);
        payload.put("codigoHmacHex", otp.hmacHex());
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", correlationId);

        OtpIssue issue =
                authPersistence.requestTwoFactor(payload);

        if (!issue.exitoso()) {
            return AppResult.error(
                    AppStatus.BAD_REQUEST,
                    "SEGUNDO_FACTOR_NO_DISPONIBLE",
                    safeMessage(
                            issue.mensaje(),
                            "No se pudo generar el segundo factor."
                    )
            );
        }

        if (!smtpEnabled) {
            if (!issue.debeEnviar() || issue.codigoUnSoloUsoId() == null) {
                return AppResult.error(AppStatus.BAD_REQUEST,
                        "OTP_DESARROLLO_NO_EMITIDO", "No se pudo emitir un código nuevo. Reintente el inicio de sesión.");
            }
            log.warn("[AUTH] DEV 2FA validado internamente por PA correlationId={}", correlationId);
            // Misma operación del PA que al ingresar el OTP manualmente, sin mostrarlo.
            return verifyTwoFactor(
                    new VerifyTwoFactorCommand(userId, otp.code(), correlationId), metadata);
        }

        if (issue.debeEnviar()
                && !deliverOtp(
                        issue,
                        () -> mailPort.sendTwoFactor(
                                issue.correoDestino(),
                                otp.code()
                        )
                )) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    "CORREO_NO_DISPONIBLE",
                    "No se pudo enviar el código de seguridad. Intente nuevamente."
            );
        }

        AuthChallenge challenge = new AuthChallenge(
                AuthStep.TWO_FACTOR_REQUIRED,
                userId,
                null,
                correlationId,
                maskEmail(issue.correoDestino())
        );

        return AppResult.ok(
                "SEGUNDO_FACTOR_REQUERIDO",
                "Revise su correo e ingrese el código de seguridad.",
                new LoginResult(
                        AuthStep.TWO_FACTOR_REQUIRED,
                        null,
                        null,
                        challenge
                )
        );
    }

    private AppResult<LoginResult> createAuthenticatedSession(
            Long userId,
            UUID correlationId,
            RequestMetadata metadata
    ) {
        RefreshTokenPort.PendingRefreshToken refresh =
                refreshTokenPort.generate();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", userId);
        payload.put(
                "dispositivoHashHex",
                deviceFingerprint.fingerprint(metadata)
        );
        payload.put(
                "refreshTokenHashHex",
                refresh.hashHex()
        );
        payload.put("navegador", metadata.navegador());
        payload.put(
                "sistemaOperativo",
                metadata.sistemaOperativo()
        );
        payload.put("userAgent", metadata.userAgent());
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", correlationId);

        SessionState session =
                authPersistence.createSession(payload);

        if (!session.exitoso()
                || session.sesionPublicaId() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "SESION_NO_CREADA",
                    safeMessage(
                            session.mensaje(),
                            "No se pudo iniciar la sesión."
                    )
            );
        }

        return authenticatedResult(
                userId,
                session,
                refresh,
                metadata
        );
    }

    private AppResult<LoginResult> authenticatedResult(
            Long userId,
            SessionState session,
            RefreshTokenPort.PendingRefreshToken refresh,
            RequestMetadata metadata
    ) {
        AuthPersistencePort.AccessContextResult contextResult =
                authPersistence.accessContext(
                        userId,
                        session.sesionPublicaId()
                );

        if (!contextResult.exitoso()
                || contextResult.contexto() == null) {
            return AppResult.error(
                    AppStatus.UNAUTHORIZED,
                    "CONTEXTO_NO_DISPONIBLE",
                    "La sesión fue creada, pero no se pudo cargar su acceso. Inicie sesión nuevamente."
            );
        }

        AccessTokenPort.IssuedAccessToken access =
                accessTokenPort.issue(
                        contextResult.contexto()
                );

        notifyNewDeviceIfRequired(
                userId,
                session,
                contextResult.contexto(),
                metadata
        );

        TokenSet tokens = new TokenSet(
                access.token(),
                "Bearer",
                access.expiresAt(),
                refreshTokenPort.compose(
                        session.sesionPublicaId(),
                        refresh.secret()
                ),
                session.expiracionRenovacionUtc(),
                session.sesionPublicaId()
        );

        return AppResult.ok(
                "LOGIN_EXITOSO",
                "Sesión iniciada correctamente.",
                new LoginResult(
                        AuthStep.AUTHENTICATED,
                        tokens,
                        contextResult.contexto(),
                        null
                )
        );
    }

    private void notifyNewDeviceIfRequired(
            Long userId,
            SessionState session,
            AccessContext context,
            RequestMetadata metadata
    ) {
        if (!smtpEnabled) {
            return;
        }
        if (session == null
                || !session.nuevoDispositivo()
                || context == null
                || context.usuario() == null) {
            return;
        }

        String destination = context.usuario().correoSeguridad();

        if (destination == null || destination.isBlank()) {
            log.warn(
                    "[MAIL] New-device notification skipped userId={} reason=no_destination",
                    userId
            );
            return;
        }

        UUID correlationId = metadata == null
                ? null
                : metadata.correlacionId();

        Long notificationId = null;

        try {
            notificationId = notificationPort.registerNewDevice(
                    userId,
                    destination,
                    metadata == null ? null : metadata.navegador(),
                    metadata == null ? null : metadata.sistemaOperativo(),
                    metadata == null ? null : metadata.ip(),
                    correlationId
            );
        } catch (RuntimeException exception) {
            log.error(
                    "[MAIL] New-device notification persistence failed userId={} correlationId={}",
                    userId,
                    correlationId
            );
            log.debug(
                    "[MAIL] New-device persistence detail",
                    exception
            );
        }

        try {
            mailPort.sendNewDevice(
                    destination,
                    metadata == null ? null : metadata.navegador(),
                    metadata == null ? null : metadata.sistemaOperativo(),
                    metadata == null ? null : metadata.ip()
            );

            markNotificationResultSafely(
                    notificationId,
                    "ENVIADO",
                    null,
                    "NUEVO_DISPOSITIVO",
                    correlationId
            );
        } catch (RuntimeException exception) {
            String failure = mailFailureSummary(exception);

            log.error(
                    "[MAIL] New-device notification failed userId={} correlationId={} error={}",
                    userId,
                    correlationId,
                    failure
            );

            markNotificationResultSafely(
                    notificationId,
                    "FALLIDO",
                    failure,
                    "NUEVO_DISPOSITIVO",
                    correlationId
            );
        }
    }

    private Map<String, Object> loginDecisionPayload(
            Long userId,
            String username,
            boolean passwordValid,
            String deviceHash,
            RequestMetadata metadata
    ) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", userId);
        payload.put("nombreUsuario", username);
        payload.put("passwordValida", passwordValid);
        payload.put("ip", metadata.ip());
        payload.put("userAgent", metadata.userAgent());
        payload.put("dispositivoHashHex", deviceHash);
        payload.put(
                "correlacionId",
                metadata.correlacionId()
        );
        return payload;
    }

    private boolean deliverOtp(
            OtpIssue issue,
            Runnable sender
    ) {
        return deliverOtp(
                "SECURITY_OTP",
                null,
                issue,
                sender
        );
    }

    private boolean deliverOtp(
            String mailEvent,
            UUID correlationId,
            OtpIssue issue,
            Runnable sender
    ) {
        if (!smtpEnabled) {
            return false;
        }
        String event = safeLogValue(mailEvent);

        String recipient =
                issue == null
                        ? "(no recipient)"
                        : maskEmail(issue.correoDestino());

        Long notificationId =
                issue == null
                        ? null
                        : issue.notificacionSeguridadId();

        log.info(
                "[MAIL] Sending type={} recipient={}",
                event,
                recipient
        );

        try {
            sender.run();

        } catch (RuntimeException exception) {
            String failure =
                    mailFailureSummary(exception);

            log.error(
                    "[MAIL] Send failed type={} recipient={} error={}",
                    event,
                    recipient,
                    failure
            );

            log.debug(
                    "[MAIL] Send failure detail type={} correlationId={}",
                    event,
                    correlationId,
                    exception
            );

            markNotificationResultSafely(
                    notificationId,
                    "FALLIDO",
                    failure,
                    event,
                    correlationId
            );

            return false;
        }

        log.info(
                "[MAIL] Sent type={} recipient={}",
                event,
                recipient
        );

        markNotificationResultSafely(
                notificationId,
                "ENVIADO",
                null,
                event,
                correlationId
        );

        return true;
    }

    private void markNotificationResultSafely(
            Long notificationId,
            String status,
            String detail,
            String mailEvent,
            UUID correlationId
    ) {
        if (notificationId == null) {
            log.debug(
                    "[MAIL] Notification persistence skipped type={} status={}",
                    safeLogValue(mailEvent),
                    status
            );
            return;
        }

        try {
            notificationPort.markResult(
                    notificationId,
                    status,
                    detail
            );

        } catch (RuntimeException exception) {
            log.error(
                    "[MAIL] Notification status update failed type={} status={} error={}",
                    safeLogValue(mailEvent),
                    status,
                    safeLogValue(exception.getMessage())
            );

            log.debug(
                    "[MAIL] Notification status failure detail type={} correlationId={}",
                    safeLogValue(mailEvent),
                    correlationId,
                    exception
            );
        }
    }

    private String mailFailureSummary(
            RuntimeException exception
    ) {
        String message = safeLogValue(
                exception.getMessage()
        );

        String value =
                exception.getClass().getSimpleName()
                        + ": "
                        + message;

        return value.length() <= 280
                ? value
                : value.substring(0, 280);
    }

    private String safeLogValue(
            Object value
    ) {
        if (value == null) {
            return "(null)";
        }

        String text = value.toString()
                .replace('\r', ' ')
                .replace('\n', ' ')
                .trim();

        if (text.isEmpty()) {
            return "(vacio)";
        }

        return text.length() <= 300
                ? text
                : text.substring(0, 300);
    }

    private boolean safeMatches(
            String rawPassword,
            String encodedPassword
    ) {
        try {
            return passwordHash.matches(
                    rawPassword == null ? "" : rawPassword,
                    encodedPassword
            );
        } catch (RuntimeException exception) {
            return false;
        }
    }

    private String normalizeUsername(String value) {
        return value == null ? "" : value.trim();
    }

    private String safeUpper(String value) {
        return value == null
                ? ""
                : value.trim().toUpperCase();
    }

    private String safeMessage(
            String message,
            String fallback
    ) {
        return message == null || message.isBlank()
                ? fallback
                : message;
    }

    private String maskEmail(String email) {
        if (email == null || email.isBlank()) {
            return null;
        }

        int at = email.indexOf('@');

        if (at <= 1) {
            return "***" + email.substring(Math.max(0, at));
        }

        String local = email.substring(0, at);
        String domain = email.substring(at);

        return local.charAt(0)
                + "***"
                + local.charAt(local.length() - 1)
                + domain;
    }

    private UUID firstNonNull(
            UUID first,
            UUID second
    ) {
        return first != null ? first : second;
    }
}
