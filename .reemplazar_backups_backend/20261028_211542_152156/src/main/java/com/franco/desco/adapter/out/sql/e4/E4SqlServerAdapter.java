package com.franco.desco.adapter.out.sql.e4;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.e4.port.out.E4PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class E4SqlServerAdapter implements E4PersistencePort {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    public E4SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> execute(Execute cmd, SessionIdentity user,
                                            RequestMetadata meta, Class<T> responseType) {
        try {
            Map<String, Object> context = new LinkedHashMap<>();
            context.put("sesionPublicaId", user.sesionPublicaId());
            context.put("correlacionId", meta.correlacionId());
            context.put("solicitudId", meta.solicitudId());
            context.put("claveIdempotencia", meta.claveIdempotencia());
            context.put("ip", meta.ip());
            context.put("endpoint", meta.endpoint());
            Map<String, Object> filters = new LinkedHashMap<>();
            filters.put("campaniaId", cmd.campaniaId());
            filters.put("operativoSocioId", cmd.operativoSocioId());
            filters.put("asignacionId", cmd.asignacionId());
            filters.put("unidadId", cmd.unidadId());
            filters.put("entregaId", cmd.entregaId());
            String payload = json.writeValueAsString(Map.of("contexto", context, "filtros", filters,
                    "datos", cmd.datos() == null ? Map.of() : cmd.datos()));

            return jdbc.execute(connection -> {
                try (CallableStatement statement = connection.prepareCall("{call comercial.PA_APAPPSS_E4_Ejecutar(?,?,?,?,?,?,?)}")) {
                    statement.setString(1, cmd.accion());
                    statement.setString(2, payload);
                    statement.registerOutParameter(3, Types.NVARCHAR);
                    statement.registerOutParameter(4, Types.BIT);
                    statement.registerOutParameter(5, Types.NVARCHAR);
                    statement.registerOutParameter(6, Types.VARCHAR);
                    statement.registerOutParameter(7, Types.SMALLINT);
                    statement.execute();
                    boolean success = statement.getBoolean(4);
                    String message = statement.getString(5);
                    String code = statement.getString(6);
                    int status = statement.getInt(7);
                    if (!success) return PersistenceResult.<T>error(code, message, status == 0 ? 400 : status);
                    String response = statement.getString(3);
                    T data = response == null ? null : json.readValue(response, responseType);
                    return PersistenceResult.ok(code, message, status == 0 ? 200 : status, data);
                }
            });
        } catch (Exception exception) {
            return PersistenceResult.error("E4_NO_DISPONIBLE", "No se pudo completar la operación comercial.", 503);
        }
    }
}
