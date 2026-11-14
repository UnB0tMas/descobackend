package com.franco.desco.adapter.out.persistence.planta;

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
import java.util.List;
import java.util.Map;

/** Adaptador de expediente: la autorización y las escrituras atómicas viven en el PA. */
@Repository
public class E3ExpedienteE4SqlAdapter {
    private static final Logger log = LoggerFactory.getLogger(E3ExpedienteE4SqlAdapter.class);
    private static final String CALL = "{call prod.PA_E3_ExpedienteE4_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E3ExpedienteE4SqlAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    public PersistenceResult<Object> execute(String action, Long uotId, Long convenioId,
            Long predioId, Long plantaId, Long episodioId, Object data,
            SessionIdentity identity, RequestMetadata metadata) {
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
        filtros.put("uotId", uotId);
        filtros.put("convenioId", convenioId);
        filtros.put("predioId", predioId);
        filtros.put("plantaId", plantaId);
        filtros.put("episodioId", episodioId);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("contexto", contexto);
        payload.put("filtros", filtros);
        payload.put("datos", data == null ? Map.of() : data);
        String requestJson = json.writeValueAsString(payload);
        try {
            return jdbc.execute(connection -> {
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
                String code = statement.getString(6);
                String message = statement.getNString(5);
                int status = statement.getInt(7);
                if (!ok) {
                    // Mostrar al usuario solo mensajes seguros. El diagnóstico permanece en el servidor.
                    log.warn("Materia seca / expediente APAPPSS rechazado: accion={}, uotId={}, convenioId={}, predioId={}, "
                                    + "codigo={}, http={}, correlacionId={}",
                            action, uotId, convenioId, predioId, code, status, metadata.correlacionId());
                    return PersistenceResult.error(code, message, status == 0 ? 400 : status);
                }
                String raw = statement.getNString(3);
                Object value = raw == null || raw.isBlank() ? null : json.readValue(raw, Object.class);
                if ("SECA_PREDIO_LISTAR".equals(action) && value instanceof Map<?, ?> fields) {
                    Object items = fields.get("items");
                    if (items instanceof String serialized) {
                        items = json.readValue(serialized, Object.class);
                    }
                    if (items == null) items = List.of();
                    if (!(items instanceof List<?>)) {
                        return PersistenceResult.error("E4_LISTADO_INVALIDO", "No se pudo cargar la información.", 502);
                    }
                    Map<Object, Object> normalized = new LinkedHashMap<>(fields);
                    normalized.put("items", items);
                    value = normalized;
                }
                return PersistenceResult.ok(code, message, status == 0 ? 200 : status, value);
            });
        } catch (DataAccessException ex) {
            // Nunca devolver SQL, parámetros de sesión ni trazas técnicas al navegador.
            log.error("Error SQL APAPPSS: accion={}, uotId={}, convenioId={}, predioId={}, correlacionId={}",
                    action, uotId, convenioId, predioId, metadata.correlacionId(), ex);
            return PersistenceResult.error("E4_BD_NO_DISPONIBLE",
                    "No se pudo completar la solicitud.", 503);
        } catch (RuntimeException ex) {
            // Incluye fallos de conversion del JSON retornado por SQL Server.
            log.error("Respuesta E4 invalida: accion={}, uotId={}, convenioId={}, predioId={}, correlacionId={}",
                    action, uotId, convenioId, predioId, metadata.correlacionId(), ex);
            return PersistenceResult.error("E4_RESPUESTA_INVALIDA",
                    "No se pudo completar la solicitud.", 503);
        }
    }
}
