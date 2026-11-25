package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.fieldtrip.documental.port.out.SalidaDocumentalPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class SalidaDocumentalSqlServerRepository implements SalidaDocumentalPersistencePort {
    private static final Logger LOG = LoggerFactory.getLogger(SalidaDocumentalSqlServerRepository.class);
    private static final String PA = "{call campo.PA_SalidaDocumental_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public SalidaDocumentalSqlServerRepository(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public PersistenceResult<Object> ejecutar(SalidaDocumentalCommand command,
                                                SessionIdentity identity, RequestMetadata metadata) {
        if (metadata == null)
            return PersistenceResult.error("SALIDA_DOC_SESION", "Inicie sesión nuevamente.", 401);
        Map<String, Object> contexto = new LinkedHashMap<>();
        contexto.put("sesionPublicaId", identity.sesionPublicaId());
        contexto.put("correlacionId", metadata.correlacionId());
        contexto.put("solicitudId", metadata.solicitudId());
        contexto.put("claveIdempotencia", metadata.claveIdempotencia());
        contexto.put("ip", metadata.ip());
        contexto.put("endpoint", metadata.endpoint());
        contexto.put("userAgent", metadata.userAgent());
        contexto.put("deviceId", metadata.deviceId());
        Map<String, Object> filtros = new LinkedHashMap<>();
        filtros.put("uotId", command.uotId());
        filtros.put("salidaId", command.salidaId());
        filtros.put("documentoId", command.documentoId());
        try {
            String payload = json.writeValueAsString(Map.of(
                    "contexto", contexto, "filtros", filtros,
                    "datos", command.datos() == null ? Map.of() : command.datos()));
            return PaTrace.call(PA, command.accion(), () -> jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(PA);
                statement.setString(1, command.accion());
                statement.setNString(2, payload);
                statement.registerOutParameter(3, Types.LONGNVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                boolean success = statement.getBoolean(4);
                String message = statement.getNString(5);
                String code = statement.getString(6);
                int http = statement.getInt(7);
                if (!success)
                    return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                String raw = statement.getNString(3);
                Object data = raw == null || raw.isBlank() ? null : json.readValue(raw, Object.class);
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, data);
            }));
        } catch (DataAccessException ex) {
            LOG.error("Error SQL en correspondencia de salida. Correlación {}", metadata.correlacionId(), ex);
            return PersistenceResult.error("SALIDA_DOC_ERROR_SQL", "No se pudo completar la operación.", 503);
        } catch (RuntimeException ex) {
            LOG.error("Error de contrato en correspondencia de salida. Correlación {}", metadata.correlacionId(), ex);
            return PersistenceResult.error("SALIDA_DOC_ERROR", "No se pudo completar la operación.", 500);
        }
    }
}
