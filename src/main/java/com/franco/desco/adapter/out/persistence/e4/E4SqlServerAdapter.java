package com.franco.desco.adapter.out.persistence.e4;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.e4.port.out.E4PersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/** E4 centraliza permisos, cálculos, auditoría, idempotencia y concurrencia en el PA. */
@Repository("e4PersistenceSqlServerAdapter")
@Primary
public final class E4SqlServerAdapter implements E4PersistencePort {
    private static final String CALL = "{call comercial.PA_APAPPSS_E4_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E4SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> execute(Execute command, SessionIdentity identity,
                                            RequestMetadata metadata, Class<T> type) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("E4_SESION_INVALIDA", "La sesión no está disponible.", 401);
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

        Map<String, Object> filtros = new LinkedHashMap<>();
        filtros.put("campaniaId", command.campaniaId());
        filtros.put("operativoSocioId", command.operativoSocioId());
        filtros.put("asignacionId", command.asignacionId());
        filtros.put("unidadId", command.unidadId());
        filtros.put("entregaId", command.entregaId());
        String payload = json.writeValueAsString(Map.of(
                "contexto", contexto, "filtros", filtros,
                "datos", command.datos() == null ? Map.of() : command.datos()));
        try {
            return jdbc.execute(connection -> {
                CallableStatement stmt = connection.prepareCall(CALL);
                stmt.setString(1, command.accion());
                stmt.setNString(2, payload);
                stmt.registerOutParameter(3, Types.LONGNVARCHAR);
                stmt.registerOutParameter(4, Types.BIT);
                stmt.registerOutParameter(5, Types.NVARCHAR);
                stmt.registerOutParameter(6, Types.VARCHAR);
                stmt.registerOutParameter(7, Types.SMALLINT);
                return stmt;
            }, (CallableStatement stmt) -> {
                stmt.execute();
                String code = stmt.getString(6);
                String message = stmt.getNString(5);
                int http = stmt.getInt(7);
                if (!stmt.getBoolean(4)) {
                    return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                }
                String raw = stmt.getNString(3);
                T value = raw == null || raw.isBlank() ? null : json.readValue(raw, type);
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, value);
            });
        } catch (DataAccessException exception) {
            return PersistenceResult.error("E4_BD_NO_DISPONIBLE",
                    "No se pudo completar la operación comercial en este momento.", 503);
        }
    }
}
