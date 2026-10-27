package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.auth.port.out.AuthPersistencePort;
import com.franco.desco.application.auth.port.out.AuthorizationPort;
import com.franco.desco.application.auth.port.out.SecurityNotificationPort;
import com.franco.desco.application.auth.port.out.SessionValidationPort;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.auth.*;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Repository
public final class AuthSqlServerAdapter
        implements AuthPersistencePort,
        AuthorizationPort,
        SessionValidationPort,
        SecurityNotificationPort {

    private final SqlServerPaExecutor executor;
    private final DatabaseRecordMapper mapper;
    private final JsonMapper jsonMapper;

    public AuthSqlServerAdapter(
            SqlServerPaExecutor executor,
            DatabaseRecordMapper mapper,
            JsonMapper jsonMapper
    ) {
        this.executor = executor;
        this.mapper = mapper;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public Optional<Credential> findCredential(
            String username
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Usuario_Sel_CredencialLogin",
                        Map.of(
                                "nombreUsuario",
                                username == null
                                        ? ""
                                        : username.trim()
                        )
                );

        if (!execution.exitoso()) {
            return Optional.empty();
        }

        Long userId =
                longOutput(
                        execution,
                        "usuarioId"
                );

        String passwordHash =
                stringOutput(
                        execution,
                        "passwordHash"
                );

        if (userId == null
                || passwordHash == null
                || passwordHash.isBlank()) {
            return Optional.empty();
        }

        return Optional.of(
                new Credential(
                        userId,
                        passwordHash
                )
        );
    }

    @Override
    public LoginDecision registerCredentialResult(
            Map<String, Object> payload
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Usuario_Upd_ResultadoCredencialLogin",
                        payload
                );

        return new LoginDecision(
                stringOutput(
                        execution,
                        "pasoSiguiente"
                ),
                booleanOutput(
                        execution,
                        "requiereSegundoFactor"
                ),
                execution.exitoso(),
                execution.mensaje()
        );
    }

    @Override
    public OtpIssue requestTwoFactor(
            Map<String, Object> payload
    ) {
        return otpIssue(
                json(
                        "seg.PA_Usuario_Ins_SolicitarSegundoFactor",
                        payload
                )
        );
    }

    @Override
    public SessionState verifyTwoFactor(
            Map<String, Object> payload
    ) {
        return sessionState(
                json(
                        "seg.PA_Usuario_Upd_ValidarSegundoFactor",
                        payload
                )
        );
    }

    @Override
    public OtpIssue requestEmailVerification(
            Map<String, Object> payload
    ) {
        return otpIssue(
                json(
                        "seg.PA_Usuario_Ins_SolicitarValidacionCorreo",
                        payload
                )
        );
    }

    @Override
    public ProcedureResult verifyEmail(
            Map<String, Object> payload
    ) {
        return procedureResult(
                json(
                        "seg.PA_Usuario_Upd_ValidarCorreo",
                        payload
                )
        );
    }

    @Override
    public OtpIssue requestPasswordRecovery(
            Map<String, Object> payload
    ) {
        return otpIssue(
                json(
                        "seg.PA_Usuario_Ins_SolicitarRecuperacionPassword",
                        payload
                )
        );
    }

    @Override
    public ProcedureResult resetPassword(
            Map<String, Object> payload
    ) {
        return procedureResult(
                json(
                        "seg.PA_Usuario_Upd_RestablecerPassword",
                        payload
                )
        );
    }

    @Override
    public RefreshRotation rotateRefresh(
            Map<String, Object> payload
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Sesion_Upd_RotarRefreshToken",
                        payload
                );

        return new RefreshRotation(
                longOutput(
                        execution,
                        "usuarioId"
                ),
                integerOutput(
                        execution,
                        "tokenVersion"
                ),
                instantOutput(
                        execution,
                        "expiracionRenovacion"
                ),
                execution.exitoso(),
                execution.mensaje()
        );
    }

    @Override
    public SessionState createSession(
            Map<String, Object> payload
    ) {
        return sessionState(
                json(
                        "seg.PA_Sesion_Ins_Crear",
                        payload
                )
        );
    }

    @Override
    public AccessContextResult accessContext(
            Long userId,
            UUID sessionPublicId
    ) {
        PaExecution execution =
                json(
                        "seg.PA_Usuario_Sel_ContextoAcceso",
                        Map.of(
                                "usuarioId",
                                userId,
                                "sesionPublicaId",
                                sessionPublicId
                        )
                );

        if (!execution.exitoso()) {
            return new AccessContextResult(
                    false,
                    execution.mensaje(),
                    null
            );
        }

        AccessContext context =
                mapper.aggregate(
                        execution.resultSets(),
                        AccessContext.class
                );

        return new AccessContextResult(
                context != null,
                execution.mensaje(),
                context
        );
    }

    @Override
    public ProcedureResult closeSession(
            Map<String, Object> payload
    ) {
        return procedureResult(
                json(
                        "seg.PA_Sesion_Upd_Cerrar",
                        payload
                )
        );
    }

    @Override
    public ProcedureResult closeOtherSessions(
            Map<String, Object> payload
    ) {
        return procedureResult(
                json(
                        "seg.PA_Sesion_Upd_CerrarOtras",
                        payload
                )
        );
    }

    @Override
    public boolean hasPermission(
            SessionIdentity identity,
            String permissionCode
    ) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null
                || permissionCode == null
                || permissionCode.isBlank()) {
            return false;
        }

        PaExecution execution =
                executor.execute(
                        "seg.PA_Autorizacion_Sel_ValidarPermiso",
                        Map.of(
                                "usuarioId",
                                identity.usuarioId(),
                                "sesionPublicaId",
                                identity.sesionPublicaId(),
                                "codigoPermiso",
                                permissionCode.trim()
                        )
                );

        return execution.exitoso()
                && booleanOutput(
                execution,
                "autorizado"
        );
    }

    @Override
    public boolean isValid(
            SessionIdentity identity,
            String jtiHashHex,
            String ip
    ) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null
                || identity.tokenVersion() == null
                || jtiHashHex == null
                || jtiHashHex.isBlank()) {
            return false;
        }

        PaExecution execution =
                json(
                        "seg.PA_Sesion_Sel_Validar",
                        Map.of(
                                "usuarioId",
                                identity.usuarioId(),
                                "sesionPublicaId",
                                identity.sesionPublicaId(),
                                "tokenVersion",
                                identity.tokenVersion(),
                                "jtiHashHex",
                                jtiHashHex,
                                "ip",
                                ip == null ? "" : ip
                        )
                );

        return execution.exitoso();
    }

    @Override
    public void markResult(
            Long securityNotificationId,
            String result,
            String detail
    ) {
        if (securityNotificationId == null) {
            return;
        }

        String state =
                "ENVIADO".equalsIgnoreCase(result)
                        ? "ENVIADO"
                        : "FALLIDO";

        json(
                "seg.PA_Seguridad_Upd_NotificacionResultado",
                Map.of(
                        "notificacionSeguridadId",
                        securityNotificationId,
                        "estadoEnvio",
                        state,
                        "proveedorMensajeId",
                        detail == null ? "" : detail
                )
        );
    }

    private OtpIssue otpIssue(
            PaExecution execution
    ) {
        return new OtpIssue(
                longOutput(
                        execution,
                        "codigoUnSoloUsoId"
                ),
                longOutput(
                        execution,
                        "notificacionSeguridadId"
                ),
                stringOutput(
                        execution,
                        "correoDestino"
                ),
                booleanOutput(
                        execution,
                        "debeEnviar"
                ),
                execution.exitoso(),
                execution.mensaje()
        );
    }

    private SessionState sessionState(
            PaExecution execution
    ) {
        return new SessionState(
                longOutput(
                        execution,
                        "sesionUsuarioId"
                ),
                uuidOutput(
                        execution,
                        "sesionPublicaId"
                ),
                instantOutput(
                        execution,
                        "expiracionRenovacion"
                ),
                booleanOutput(
                        execution,
                        "nuevoDispositivo"
                ),
                execution.exitoso(),
                execution.mensaje()
        );
    }

    private ProcedureResult procedureResult(
            PaExecution execution
    ) {
        return new ProcedureResult(
                execution.exitoso(),
                execution.mensaje()
        );
    }

    private PaExecution json(
            String procedure,
            Map<String, ?> payload
    ) {
        return executor.execute(
                procedure,
                Map.of(
                        "cJson",
                        write(payload)
                )
        );
    }

    private String write(Map<String, ?> payload) {
        try {
            return jsonMapper.writeValueAsString(
                    payload == null
                            ? Map.of()
                            : payload
            );
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo preparar la operación de seguridad.",
                    exception
            );
        }
    }

    private Object output(
            PaExecution execution,
            String key
    ) {
        String normalized =
                normalize(key);

        for (Map.Entry<String, Object> entry
                : execution.outputs().entrySet()) {
            if (normalize(
                    entry.getKey()
            ).equals(normalized)) {
                return entry.getValue();
            }
        }

        return null;
    }

    private String stringOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        return value == null
                ? null
                : value.toString().trim();
    }

    private Long longOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        return value instanceof Number number
                ? number.longValue()
                : null;
    }

    private Integer integerOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        return value instanceof Number number
                ? number.intValue()
                : null;
    }

    private boolean booleanOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        if (value instanceof Boolean bool) {
            return bool;
        }

        if (value instanceof Number number) {
            return number.intValue() != 0;
        }

        return value != null
                && Boolean.parseBoolean(
                value.toString()
        );
    }

    private UUID uuidOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        if (value instanceof UUID uuid) {
            return uuid;
        }

        if (value == null) {
            return null;
        }

        try {
            return UUID.fromString(
                    value.toString()
            );
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private Instant instantOutput(
            PaExecution execution,
            String key
    ) {
        Object value =
                output(execution, key);

        if (value instanceof Instant instant) {
            return instant;
        }

        if (value instanceof java.time.LocalDateTime dateTime) {
            return dateTime.toInstant(
                    java.time.ZoneOffset.UTC
            );
        }

        return null;
    }

    private String normalize(String value) {
        return value == null
                ? ""
                : value
                .replace("_", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}
