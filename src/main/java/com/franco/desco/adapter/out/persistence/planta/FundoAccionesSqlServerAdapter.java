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
public class FundoAccionesSqlServerAdapter {
    public enum Accion { CONSULTAR, CAMBIAR, RETIRAR }

    private final JdbcTemplate jdbc;
    private final JsonMapper mapper;

    public FundoAccionesSqlServerAdapter(JdbcTemplate jdbc, JsonMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    public <T> PersistenceResult<T> execute(Accion accion, Long uotId, Long convenioId,
            Long predioId, Object datos, SessionIdentity identity,
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
                "filtros", Map.of("uotId", uotId, "convenioId", convenioId, "predioId", predioId),
                "datos", datos == null ? Map.of() : datos));
        String procedure = switch (accion) {
            case CONSULTAR -> "{call prod.PA_FundoHabilitacion_Sel_Estado(?,?,?,?,?,?)}";
            case CAMBIAR -> "{call prod.PA_FundoHabilitacion_Upd_Estado(?,?,?,?,?,?)}";
            case RETIRAR -> "{call prod.PA_Fundo_Upd_RetirarEnBloque(?,?,?,?,?,?)}";
        };
        try {
            return jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(procedure);
                statement.setNString(1, payload);
                statement.registerOutParameter(2, Types.LONGNVARCHAR);
                statement.registerOutParameter(3, Types.BIT);
                statement.registerOutParameter(4, Types.NVARCHAR);
                statement.registerOutParameter(5, Types.VARCHAR);
                statement.registerOutParameter(6, Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                int http = statement.getInt(6);
                String codigo = statement.getString(5);
                String mensaje = statement.getNString(4);
                if (!statement.getBoolean(3)) {
                    return PersistenceResult.error(codigo, mensaje, http == 0 ? 400 : http);
                }
                String raw = statement.getNString(2);
                T value = raw == null || raw.isBlank() ? null : mapper.readValue(raw, type);
                return PersistenceResult.ok(codigo, mensaje, http == 0 ? 200 : http, value);
            });
        } catch (DataAccessException exception) {
            return PersistenceResult.error("FUNDO_BD_NO_DISPONIBLE",
                    "No fue posible completar la operación.", 503);
        }
    }
}
