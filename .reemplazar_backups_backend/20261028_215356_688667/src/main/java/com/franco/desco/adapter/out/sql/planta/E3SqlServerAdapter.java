package com.franco.desco.adapter.out.sql.planta;

import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.planta.port.out.E3PersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class E3SqlServerAdapter implements E3PersistencePort {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E3SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> execute(Execute command, SessionIdentity identity,
                                            RequestMetadata metadata, Class<T> responseType) {
        try {
            Map<String, Object> context = new LinkedHashMap<>();
            context.put("sesionPublicaId", identity.sesionPublicaId());
            context.put("correlacionId", metadata.correlacionId());
            context.put("solicitudId", metadata.solicitudId());
            context.put("claveIdempotencia", metadata.claveIdempotencia());
            context.put("ip", metadata.ip());
            context.put("endpoint", metadata.endpoint());

            Map<String, Object> filters = new LinkedHashMap<>();
            filters.put("uotId", command.uotId());
            filters.put("convenioId", command.convenioId());
            filters.put("predioId", command.predioId());
            filters.put("plantaId", command.plantaId());
            filters.put("buscar", command.buscar());
            filters.put("estado", command.estado());
            filters.put("variedadId", command.variedadId());
            filters.put("pagina", command.pagina());
            filters.put("tamano", command.tamano());

            Map<String, Object> request = new LinkedHashMap<>();
            request.put("contexto", context);
            request.put("filtros", filters);
            request.put("datos", command.datos() == null ? Map.of() : command.datos());
            String payload = json.writeValueAsString(request);

            ConnectionCallback<PersistenceResult<T>> callback = connection -> {
                try (CallableStatement statement = connection.prepareCall(
                        "{call prod.PA_PlantaPaltaE3_Ejecutar(?,?,?,?,?,?,?)}")) {
                    statement.setString(1, command.accion());
                    statement.setString(2, payload);
                    statement.registerOutParameter(3, Types.NVARCHAR);
                    statement.registerOutParameter(4, Types.BIT);
                    statement.registerOutParameter(5, Types.NVARCHAR);
                    statement.registerOutParameter(6, Types.VARCHAR);
                    statement.registerOutParameter(7, Types.SMALLINT);
                    statement.execute();

                    String code = statement.getString(6);
                    String message = statement.getString(5);
                    int http = statement.getInt(7);
                    if (!statement.getBoolean(4)) {
                        return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                    }
                    String raw = statement.getString(3);
                    T data = raw == null ? null : json.readValue(raw, responseType);
                    return PersistenceResult.ok(code, message, http == 0 ? 200 : http, data);
                }
            };
            return jdbc.execute(callback);
        } catch (Exception ex) {
            // Nunca se exponen mensajes de SQL Server, parámetros o sesiones al cliente.
            return PersistenceResult.error("E3_NO_DISPONIBLE",
                    "No fue posible consultar el expediente técnico.", 503);
        }
    }
}
