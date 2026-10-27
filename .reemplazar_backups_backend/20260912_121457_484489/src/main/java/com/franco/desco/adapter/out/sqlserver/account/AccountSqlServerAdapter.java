package com.franco.desco.adapter.out.sqlserver.account;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.account.port.out.AccountPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.account.AccountModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class AccountSqlServerAdapter implements AccountPersistencePort {

    private final SqlServerPaExecutor executor;
    private final SimpleJdbcCall listSessions;
    private final SimpleJdbcCall closeSession;
    private final SimpleJdbcCall closeOtherSessions;
    private final SimpleJdbcCall listDevices;
    private final SimpleJdbcCall updateRecognition;
    private final SimpleJdbcCall currentCredential;
    private final SimpleJdbcCall changePassword;
    private final SimpleJdbcCall requestEmailChange;
    private final SimpleJdbcCall confirmEmailChange;

    public AccountSqlServerAdapter(SqlServerPaFactory factory, SqlServerPaExecutor executor) {
        this.executor = executor;
        this.listSessions = factory.callWithResultSets("seg", "PA_Sesion_Sel_Listado", "items");
        this.closeSession = factory.call("seg", "PA_Sesion_Upd_Cerrar");
        this.closeOtherSessions = factory.call("seg", "PA_Sesion_Upd_CerrarOtras");
        this.listDevices = factory.callWithResultSets("seg", "PA_Dispositivo_Sel_Listado", "items");
        this.updateRecognition = factory.call("seg", "PA_Dispositivo_Upd_Reconocimiento");
        this.currentCredential = factory.call("seg", "PA_Usuario_Sel_CredencialActual");
        this.changePassword = factory.call("seg", "PA_Usuario_Upd_CambiarPassword");
        this.requestEmailChange = factory.call("seg", "PA_Usuario_Ins_SolicitarCambioCorreo");
        this.confirmEmailChange = factory.call("seg", "PA_Usuario_Upd_ConfirmarCambioCorreo");
    }

    @Override
    public PersistenceResult<List<AccountModels.SessionInfo>> sessions(SessionIdentity identity, RequestMetadata metadata) {
        var rs = executor.executeJsonMultiResult(listSessions, base(identity));
        if (!PaAdapterSupport.success(rs.raw())) {
            return PersistenceResult.error(PaAdapterSupport.message(rs.raw(), "No se pudieron consultar las sesiones."));
        }
        return PersistenceResult.ok(
                PaAdapterSupport.message(rs.raw(), "Sesiones consultadas correctamente."),
                rs.rows("items").stream().map(this::session).toList()
        );
    }

    @Override
    public PersistenceResult<Void> closeSession(SessionIdentity identity, RequestMetadata metadata, UUID targetSession) {
        Map<String, Object> payload = base(identity);
        payload.put("sesionActualPublicaId", identity.sesionPublicaId());
        payload.put("sesionObjetivoPublicaId", targetSession);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());
        return PaAdapterSupport.result(executor.executeJsonMutation(closeSession, payload), null, "No se pudo cerrar la sesión.");
    }

    @Override
    public PersistenceResult<Void> closeOtherSessions(SessionIdentity identity, RequestMetadata metadata) {
        Map<String, Object> payload = base(identity);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());
        return PaAdapterSupport.result(executor.executeJsonMutation(closeOtherSessions, payload), null, "No se pudieron cerrar las demás sesiones.");
    }

    @Override
    public PersistenceResult<List<AccountModels.DeviceInfo>> devices(SessionIdentity identity, RequestMetadata metadata) {
        var rs = executor.executeJsonMultiResult(listDevices, base(identity));
        if (!PaAdapterSupport.success(rs.raw())) {
            return PersistenceResult.error(PaAdapterSupport.message(rs.raw(), "No se pudieron consultar los dispositivos."));
        }
        return PersistenceResult.ok(
                PaAdapterSupport.message(rs.raw(), "Dispositivos consultados correctamente."),
                rs.rows("items").stream().map(this::device).toList()
        );
    }

    @Override
    public PersistenceResult<Void> recognizeDevice(SessionIdentity identity, RequestMetadata metadata, Long deviceId, String action) {
        Map<String, Object> payload = base(identity);
        payload.put("dispositivoUsuarioId", deviceId);
        payload.put("accion", action);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());
        return PaAdapterSupport.result(executor.executeJsonMutation(updateRecognition, payload), null, "No se pudo actualizar el reconocimiento del dispositivo.");
    }

    @Override
    public PersistenceResult<String> currentPasswordHash(SessionIdentity identity, RequestMetadata metadata) {
        Map<String, Object> out = executor.executeJson(currentCredential, base(identity));
        return PaAdapterSupport.result(out, SqlValues.string(out, "cPasswordHash"), "No se pudo validar la credencial actual.");
    }

    @Override
    public PersistenceResult<Void> changePassword(SessionIdentity identity, RequestMetadata metadata, String newPasswordHash) {
        Map<String, Object> payload = base(identity);
        payload.put("nuevoPasswordHash", newPasswordHash);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());
        return PaAdapterSupport.result(executor.executeJsonMutation(changePassword, payload), null, "No se pudo actualizar la contraseña.");
    }

    @Override
    public PersistenceResult<AccountModels.EmailChangeIssue> requestEmailChange(
            SessionIdentity identity,
            RequestMetadata metadata,
            String newEmail,
            String codeHmacHex
    ) {
        Map<String, Object> payload = base(identity);
        payload.put("nuevoCorreo", newEmail);
        payload.put("codigoHmacHex", codeHmacHex);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());

        Map<String, Object> out = executor.executeJsonMutation(requestEmailChange, payload);
        AccountModels.EmailChangeIssue issue = new AccountModels.EmailChangeIssue(
                SqlValues.longValue(out, "nUsuarioCorreoSeguridadId"),
                SqlValues.longValue(out, "nCodigoUnSoloUsoId"),
                SqlValues.longValue(out, "nNotificacionSeguridadId"),
                SqlValues.string(out, "cCorreoDestino"),
                SqlValues.bool(out, "bDebeEnviar")
        );
        return PaAdapterSupport.result(out, issue, "No se pudo solicitar el cambio de correo.");
    }

    @Override
    public PersistenceResult<Void> confirmEmailChange(SessionIdentity identity, RequestMetadata metadata, String codeHmacHex) {
        Map<String, Object> payload = base(identity);
        payload.put("codigoHmacHex", codeHmacHex);
        payload.put("ip", metadata.ip());
        payload.put("correlacionId", metadata.correlacionId());
        return PaAdapterSupport.result(executor.executeJsonMutation(confirmEmailChange, payload), null, "No se pudo confirmar el cambio de correo.");
    }

    private Map<String, Object> base(SessionIdentity identity) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("usuarioId", identity.usuarioId());
        payload.put("sesionPublicaId", identity.sesionPublicaId());
        return payload;
    }

    private AccountModels.SessionInfo session(Map<String, Object> row) {
        return new AccountModels.SessionInfo(
                SqlValues.uuid(row, "sesionPublicaId"),
                SqlValues.instant(row, "fechaCreacionUtc"),
                SqlValues.instant(row, "fechaUltimaActividadUtc"),
                SqlValues.instant(row, "fechaExpiracionRenovacionUtc"),
                SqlValues.string(row, "ipCreacion"),
                SqlValues.string(row, "ipUltimaActividad"),
                SqlValues.bool(row, "esSesionActual"),
                SqlValues.bool(row, "estaActiva"),
                SqlValues.longValue(row, "dispositivoUsuarioId"),
                SqlValues.string(row, "navegador"),
                SqlValues.string(row, "sistemaOperativo"),
                SqlValues.instant(row, "fechaPrimeraDeteccionUtc"),
                SqlValues.instant(row, "fechaUltimaActividadDispositivoUtc"),
                SqlValues.bool(row, "esReconocido")
        );
    }

    private AccountModels.DeviceInfo device(Map<String, Object> row) {
        return new AccountModels.DeviceInfo(
                SqlValues.longValue(row, "dispositivoUsuarioId"),
                SqlValues.string(row, "navegador"),
                SqlValues.string(row, "sistemaOperativo"),
                SqlValues.instant(row, "fechaPrimeraDeteccionUtc"),
                SqlValues.instant(row, "fechaUltimaActividadUtc"),
                SqlValues.string(row, "ultimaIp"),
                SqlValues.bool(row, "esReconocidoVigente"),
                SqlValues.instant(row, "fechaReconocimientoUtc"),
                SqlValues.instant(row, "fechaExpiracionReconocimientoUtc"),
                SqlValues.bool(row, "esDispositivoActual")
        );
    }
}
