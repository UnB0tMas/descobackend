package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.*;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface AuthPersistencePort {

    Optional<Credential> findCredential(String nombreUsuario);

    LoginDecision registerCredentialResult(Map<String, Object> payload);

    OtpIssue requestEmailVerification(Map<String, Object> payload);

    ProcedureResult verifyEmail(Map<String, Object> payload);

    OtpIssue requestTwoFactor(Map<String, Object> payload);

    SessionState verifyTwoFactor(Map<String, Object> payload);

    SessionState createSession(Map<String, Object> payload);

    OtpIssue requestPasswordRecovery(Map<String, Object> payload);

    ProcedureResult resetPassword(Map<String, Object> payload);

    RefreshRotation rotateRefresh(Map<String, Object> payload);

    ProcedureResult closeSession(Map<String, Object> payload);

    ProcedureResult closeOtherSessions(Map<String, Object> payload);

    AccessContextResult accessContext(
            Long usuarioId,
            UUID sesionPublicaId
    );

    record ProcedureResult(
            boolean exitoso,
            String mensaje
    ) {
    }

    record AccessContextResult(
            boolean exitoso,
            String mensaje,
            AccessContext contexto
    ) {
    }
}
