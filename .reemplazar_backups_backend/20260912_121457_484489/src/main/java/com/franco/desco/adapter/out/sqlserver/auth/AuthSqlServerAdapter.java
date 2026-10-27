package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.PaResultSets;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.auth.port.out.AuthPersistencePort;
import com.franco.desco.domain.auth.AccessContext;
import com.franco.desco.domain.auth.AccessModule;
import com.franco.desco.domain.auth.AccessPermission;
import com.franco.desco.domain.auth.AccessRole;
import com.franco.desco.domain.auth.AccessUser;
import com.franco.desco.domain.auth.Credential;
import com.franco.desco.domain.auth.LoginDecision;
import com.franco.desco.domain.auth.OtpIssue;
import com.franco.desco.domain.auth.RefreshRotation;
import com.franco.desco.domain.auth.SessionState;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Component
public class AuthSqlServerAdapter
        implements AuthPersistencePort {

    private final SqlServerPaExecutor executor;

    private final SimpleJdbcCall credentialLoginCall;
    private final SimpleJdbcCall loginResultCall;
    private final SimpleJdbcCall requestEmailVerificationCall;
    private final SimpleJdbcCall verifyEmailCall;
    private final SimpleJdbcCall requestTwoFactorCall;
    private final SimpleJdbcCall verifyTwoFactorCall;
    private final SimpleJdbcCall createSessionCall;
    private final SimpleJdbcCall requestRecoveryCall;
    private final SimpleJdbcCall resetPasswordCall;
    private final SimpleJdbcCall rotateRefreshCall;
    private final SimpleJdbcCall closeSessionCall;
    private final SimpleJdbcCall closeOtherSessionsCall;
    private final SimpleJdbcCall accessContextCall;

    public AuthSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor
    ) {
        this.executor = executor;

        this.credentialLoginCall = factory.call(
                "seg",
                "PA_Usuario_Sel_CredencialLogin"
        );
        this.loginResultCall = factory.call(
                "seg",
                "PA_Usuario_Upd_ResultadoCredencialLogin"
        );
        this.requestEmailVerificationCall = factory.call(
                "seg",
                "PA_Usuario_Ins_SolicitarValidacionCorreo"
        );
        this.verifyEmailCall = factory.call(
                "seg",
                "PA_Usuario_Upd_ValidarCorreo"
        );
        this.requestTwoFactorCall = factory.call(
                "seg",
                "PA_Usuario_Ins_SolicitarSegundoFactor"
        );
        this.verifyTwoFactorCall = factory.call(
                "seg",
                "PA_Usuario_Upd_ValidarSegundoFactor"
        );
        this.createSessionCall = factory.call(
                "seg",
                "PA_Sesion_Ins_Crear"
        );
        this.requestRecoveryCall = factory.call(
                "seg",
                "PA_Usuario_Ins_SolicitarRecuperacionPassword"
        );
        this.resetPasswordCall = factory.call(
                "seg",
                "PA_Usuario_Upd_RestablecerPassword"
        );
        this.rotateRefreshCall = factory.call(
                "seg",
                "PA_Sesion_Upd_RotarRefreshToken"
        );
        this.closeSessionCall = factory.call(
                "seg",
                "PA_Sesion_Upd_Cerrar"
        );
        this.closeOtherSessionsCall = factory.call(
                "seg",
                "PA_Sesion_Upd_CerrarOtras"
        );
        this.accessContextCall = factory.callWithResultSets(
                "seg",
                "PA_Usuario_Sel_ContextoAcceso",
                "usuario",
                "roles",
                "modulos",
                "permisos"
        );
    }

    @Override
    public Optional<Credential> findCredential(
            String nombreUsuario
    ) {
        Map<String, Object> result = executor.executeJson(
                credentialLoginCall,
                Map.of(
                        "nombreUsuario",
                        nombreUsuario
                )
        );

        if (!SqlValues.bool(result, "bResultado")) {
            return Optional.empty();
        }

        Long userId = SqlValues.longValue(
                result,
                "nUsuarioId"
        );
        String hash = SqlValues.string(
                result,
                "cPasswordHash"
        );

        if (userId == null
                || hash == null
                || hash.isBlank()) {
            return Optional.empty();
        }

        return Optional.of(
                new Credential(
                        userId,
                        hash
                )
        );
    }

    @Override
    public LoginDecision registerCredentialResult(
            Map<String, Object> payload
    ) {
        Map<String, Object> result = executor.executeJson(
                loginResultCall,
                payload
        );

        return new LoginDecision(
                SqlValues.string(result, "cPasoSiguiente"),
                SqlValues.bool(result, "bRequiereSegundoFactor"),
                SqlValues.bool(result, "bResultado"),
                SqlValues.string(result, "cMensaje")
        );
    }

    @Override
    public OtpIssue requestEmailVerification(
            Map<String, Object> payload
    ) {
        return issue(
                requestEmailVerificationCall,
                payload
        );
    }

    @Override
    public ProcedureResult verifyEmail(
            Map<String, Object> payload
    ) {
        return simpleResult(
                verifyEmailCall,
                payload
        );
    }

    @Override
    public OtpIssue requestTwoFactor(
            Map<String, Object> payload
    ) {
        return issue(
                requestTwoFactorCall,
                payload
        );
    }

    @Override
    public SessionState verifyTwoFactor(
            Map<String, Object> payload
    ) {
        return sessionResult(
                verifyTwoFactorCall,
                payload
        );
    }

    @Override
    public SessionState createSession(
            Map<String, Object> payload
    ) {
        return sessionResult(
                createSessionCall,
                payload
        );
    }

    @Override
    public OtpIssue requestPasswordRecovery(
            Map<String, Object> payload
    ) {
        return issue(
                requestRecoveryCall,
                payload
        );
    }

    @Override
    public ProcedureResult resetPassword(
            Map<String, Object> payload
    ) {
        return simpleResult(
                resetPasswordCall,
                payload
        );
    }

    @Override
    public RefreshRotation rotateRefresh(
            Map<String, Object> payload
    ) {
        Map<String, Object> result = executor.executeJson(
                rotateRefreshCall,
                payload
        );

        return new RefreshRotation(
                SqlValues.longValue(result, "nUsuarioId"),
                SqlValues.intValue(result, "nTokenVersion"),
                SqlValues.instant(result, "dExpiracionRenovacion"),
                SqlValues.bool(result, "bResultado"),
                SqlValues.string(result, "cMensaje")
        );
    }

    @Override
    public ProcedureResult closeSession(
            Map<String, Object> payload
    ) {
        return simpleResult(
                closeSessionCall,
                payload
        );
    }

    @Override
    public ProcedureResult closeOtherSessions(
            Map<String, Object> payload
    ) {
        return simpleResult(
                closeOtherSessionsCall,
                payload
        );
    }

    @Override
    public AccessContextResult accessContext(
            Long usuarioId,
            UUID sesionPublicaId
    ) {
        PaResultSets result = executor.executeJsonMultiResult(
                accessContextCall,
                Map.of(
                        "usuarioId",
                        usuarioId,
                        "sesionPublicaId",
                        sesionPublicaId
                )
        );

        boolean success = SqlValues.bool(
                result.raw(),
                "bResultado"
        );
        String message = SqlValues.string(
                result.raw(),
                "cMensaje"
        );

        if (!success) {
            return new AccessContextResult(
                    false,
                    message,
                    null
            );
        }

        Optional<AccessUser> user = result.mapOne(
                "usuario",
                this::mapUser
        );

        if (user.isEmpty()) {
            return new AccessContextResult(
                    false,
                    "La sesión no está disponible.",
                    null
            );
        }

        List<AccessRole> roles = result.map(
                "roles",
                this::mapRole
        );
        List<AccessModule> modules = result.map(
                "modulos",
                this::mapModule
        );
        List<AccessPermission> permissions = result.map(
                "permisos",
                this::mapPermission
        );

        return new AccessContextResult(
                true,
                message,
                new AccessContext(
                        user.get(),
                        roles,
                        modules,
                        permissions
                )
        );
    }

    private OtpIssue issue(
            SimpleJdbcCall call,
            Map<String, Object> payload
    ) {
        Map<String, Object> result = executor.executeJson(
                call,
                payload
        );

        return new OtpIssue(
                SqlValues.longValue(result, "nCodigoUnSoloUsoId"),
                SqlValues.longValue(result, "nNotificacionSeguridadId"),
                SqlValues.string(result, "cCorreoDestino"),
                SqlValues.bool(result, "bDebeEnviar"),
                SqlValues.bool(result, "bResultado"),
                SqlValues.string(result, "cMensaje")
        );
    }

    private SessionState sessionResult(
            SimpleJdbcCall call,
            Map<String, Object> payload
    ) {
        Map<String, Object> result = executor.executeJson(
                call,
                payload
        );

        return new SessionState(
                SqlValues.longValue(result, "nSesionUsuarioId"),
                SqlValues.uuid(result, "gSesionPublicaId"),
                SqlValues.instant(result, "dExpiracionRenovacion"),
                SqlValues.bool(result, "bNuevoDispositivo"),
                SqlValues.bool(result, "bResultado"),
                SqlValues.string(result, "cMensaje")
        );
    }

    private ProcedureResult simpleResult(
            SimpleJdbcCall call,
            Map<String, Object> payload
    ) {
        Map<String, Object> result = executor.executeJson(
                call,
                payload
        );

        return new ProcedureResult(
                SqlValues.bool(result, "bResultado"),
                SqlValues.string(result, "cMensaje")
        );
    }

    private AccessUser mapUser(
            Map<String, Object> row
    ) {
        return new AccessUser(
                SqlValues.longValue(row, "usuarioId"),
                SqlValues.string(row, "nombreUsuario"),
                SqlValues.string(row, "estadoCuenta"),
                SqlValues.instant(row, "ultimoAccesoCorrectoUtc"),
                SqlValues.bool(row, "requiereCambioPassword"),
                SqlValues.bool(row, "segundoFactorHabilitado"),
                SqlValues.intValue(row, "tokenVersion"),
                SqlValues.longValue(row, "personaId"),
                SqlValues.string(row, "tipoDocumento"),
                SqlValues.string(row, "numeroDocumento"),
                SqlValues.string(row, "nombres"),
                SqlValues.string(row, "apellidoPaterno"),
                SqlValues.string(row, "apellidoMaterno"),
                SqlValues.string(row, "nombreCompleto"),
                SqlValues.string(row, "telefono"),
                SqlValues.string(row, "codigoEmpleado"),
                SqlValues.longValue(row, "empresaId"),
                SqlValues.string(row, "correoSeguridad"),
                SqlValues.bool(row, "correoSeguridadVerificado"),
                SqlValues.uuid(row, "sesionPublicaId"),
                SqlValues.instant(row, "fechaSesionUtc"),
                SqlValues.instant(row, "fechaExpiracionRenovacionUtc"),
                SqlValues.longValue(row, "dispositivoUsuarioId"),
                SqlValues.string(row, "navegador"),
                SqlValues.string(row, "sistemaOperativo"),
                SqlValues.bool(row, "dispositivoReconocido")
        );
    }

    private AccessRole mapRole(
            Map<String, Object> row
    ) {
        return new AccessRole(
                SqlValues.longValue(row, "rolId"),
                SqlValues.string(row, "codigoRol"),
                SqlValues.string(row, "nombreRol"),
                SqlValues.string(row, "descripcion"),
                SqlValues.bool(row, "requiereSegundoFactor")
        );
    }

    private AccessModule mapModule(
            Map<String, Object> row
    ) {
        return new AccessModule(
                SqlValues.intValue(row, "moduloId"),
                SqlValues.intValue(row, "moduloPadreId"),
                SqlValues.string(row, "codigoModulo"),
                SqlValues.string(row, "nombreModulo"),
                SqlValues.intValue(row, "orden"),
                SqlValues.string(row, "ruta"),
                SqlValues.string(row, "icono"),
                SqlValues.bool(row, "visibleMenu"),
                SqlValues.bool(row, "esGrupo")
        );
    }

    private AccessPermission mapPermission(
            Map<String, Object> row
    ) {
        return new AccessPermission(
                SqlValues.longValue(row, "permisoId"),
                SqlValues.intValue(row, "moduloId"),
                SqlValues.string(row, "codigoModulo"),
                SqlValues.string(row, "codigoPermiso"),
                SqlValues.string(row, "nombrePermiso"),
                SqlValues.string(row, "descripcion"),
                SqlValues.string(row, "accion"),
                SqlValues.bool(row, "esSensible"),
                SqlValues.bool(row, "requiereMotivo")
        );
    }
}
