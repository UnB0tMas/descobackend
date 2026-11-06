package com.franco.desco.adapter.out.persistence.planta;

import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.planta.port.out.E3PersistencePort;
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

/** El PA valida ámbito, permisos, concurrencia e idempotencia; Java no duplica esas reglas. */
@Repository("e3PersistenceSqlServerAdapter")
@Primary
public final class E3SqlServerAdapter implements E3PersistencePort {
    private static final String CALL = "{call prod.PA_PlantaPaltaE3_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper mapper;

    public E3SqlServerAdapter(JdbcTemplate jdbc, JsonMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    @Override
    public <T> PersistenceResult<T> execute(Execute command, SessionIdentity identity,
                                            RequestMetadata metadata, Class<T> type) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("E3_SESION_INVALIDA", "Su sesión no está disponible.", 401);
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
        filtros.put("uotId", command.uotId());
        filtros.put("convenioId", command.convenioId());
        filtros.put("predioId", command.predioId());
        filtros.put("plantaId", command.plantaId());
        filtros.put("buscar", command.buscar());
        filtros.put("estado", command.estado());
        filtros.put("variedadId", command.variedadId());
        filtros.put("pagina", command.pagina());
        filtros.put("tamano", command.tamano());
        String payload = mapper.writeValueAsString(Map.of(
                "contexto", contexto, "filtros", filtros,
                "datos", command.datos() == null ? Map.of() : command.datos()));
        try {
            return jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(CALL);
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
                int status = statement.getInt(7);
                if (!success) return PersistenceResult.error(code, message, status == 0 ? 400 : status);
                String json = statement.getNString(3);
                T data = json == null || json.isBlank() ? null : mapper.readValue(json, type);
                return PersistenceResult.ok(code, message, status == 0 ? 200 : status, data);
            });
        } catch (DataAccessException exception) {
            return PersistenceResult.error("E3_BD_NO_DISPONIBLE",
                    "No se pudo completar la operación en este momento.", 503);
        }
    }
}
