package com.franco.desco.adapter.out.sqlserver.correspondence;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Casos de uso de correspondencia interna. El PA controla la sesión, la UOT,
 * los participantes y todas las transiciones; Java no duplica esas reglas.
 */
@Repository
public class CorrespondenceSqlServerRepository {
    private static final String CALL = "{call doc.PA_Correspondencia_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public CorrespondenceSqlServerRepository(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @SuppressWarnings("unchecked")
    public <T> AppResult<T> execute(String action, Object data, SessionIdentity identity,
                                   RequestMetadata metadata, Class<T> resultType) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return AppResult.error(AppStatus.UNAUTHORIZED, "DOCS_SESION_INVALIDA", "Sesión no disponible.");
        }
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("sesionPublicaId", identity.sesionPublicaId());
        context.put("correlacionId", metadata.correlacionId());
        context.put("solicitudId", metadata.solicitudId());
        context.put("claveIdempotencia", metadata.claveIdempotencia());
        context.put("ip", metadata.ip());
        context.put("endpoint", metadata.endpoint());
        context.put("userAgent", metadata.userAgent());
        context.put("deviceId", metadata.deviceId());
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contexto", context);
        payload.put("datos", data == null ? Map.of() : data);
        final String requestJson = json.writeValueAsString(payload);
        try {
            return PaTrace.call(CALL, action, () -> jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(CALL);
                statement.setString(1, action);
                statement.setNString(2, requestJson);
                statement.registerOutParameter(3, Types.LONGNVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                boolean ok = statement.getBoolean(4);
                String message = statement.getNString(5);
                String code = statement.getString(6);
                int http = statement.getInt(7);
                if (!ok) return AppResult.error(AppStatus.fromHttp(http, AppStatus.BAD_REQUEST), code, message);
                String body = statement.getNString(3);
                T value = body == null || body.isBlank() ? null : json.readValue(body, resultType);
                if (http == 201) return AppResult.created(code, message, value);
                return AppResult.ok(code, message, value);
            }));
        } catch (DataAccessException exception) {
            return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "DOCS_BD_NO_DISPONIBLE",
                    "No se pudo procesar la solicitud de correspondencia.");
        }
    }
}
