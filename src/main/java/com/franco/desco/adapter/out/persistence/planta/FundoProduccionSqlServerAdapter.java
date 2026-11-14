package com.franco.desco.adapter.out.persistence.planta;

import com.franco.desco.application.shared.PersistenceResult;
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

@Repository
public class FundoProduccionSqlServerAdapter {
    private static final String CALL = "{call prod.PA_FundoProduccionE3_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper mapper;

    public FundoProduccionSqlServerAdapter(JdbcTemplate jdbc, JsonMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    public <T> PersistenceResult<T> execute(String accion, Long uotId, Long convenioId,
            Long predioId, Integer anio, Object datos, SessionIdentity identity,
            RequestMetadata metadata, Class<T> type) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("FUNDO_SESION_INVALIDA", "Su sesión no está disponible.", 401);
        }
        Map<String, Object> contexto = new LinkedHashMap<>();
        contexto.put("sesionPublicaId", identity.sesionPublicaId());
        contexto.put("correlacionId", metadata.correlacionId());
        contexto.put("solicitudId", metadata.solicitudId());
        contexto.put("claveIdempotencia", metadata.claveIdempotencia());
        contexto.put("ip", metadata.ip());
        contexto.put("endpoint", metadata.endpoint());
        contexto.put("userAgent", metadata.userAgent());
        contexto.put("deviceId", metadata.deviceId());
        String payload = mapper.writeValueAsString(Map.of(
                "contexto", contexto,
                "filtros", Map.of("uotId", uotId, "convenioId", convenioId,
                        "predioId", predioId, "anio", anio),
                "datos", datos == null ? Map.of() : datos));
        try {
            return jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(CALL);
                statement.setString(1, accion);
                statement.setNString(2, payload);
                statement.registerOutParameter(3, Types.LONGNVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                String message = statement.getNString(5);
                String code = statement.getString(6);
                int http = statement.getInt(7);
                if (!statement.getBoolean(4)) {
                    return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                }
                String raw = statement.getNString(3);
                T value = raw == null || raw.isBlank() ? null : mapper.readValue(raw, type);
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, value);
            });
        } catch (DataAccessException exception) {
            return PersistenceResult.error("FUNDO_BD_NO_DISPONIBLE",
                    "No se pudo procesar la producción del fundo.", 503);
        }
    }
}
