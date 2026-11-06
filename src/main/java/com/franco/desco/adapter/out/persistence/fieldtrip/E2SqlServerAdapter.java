package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.out.E2PersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.fieldtrip.E2Models;
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

/** Adaptador E2: todas las decisiones y mutaciones pasan por el procedimiento existente. */
@Repository
public final class E2SqlServerAdapter implements E2PersistencePort {
    private static final Logger LOG = LoggerFactory.getLogger(E2SqlServerAdapter.class);
    private static final String PROCEDURE = "{call campo.PA_SalidaOperativaE2_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E2SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    private <T> PersistenceResult<T> ejecutar(String accion, Long uotId, Long convenioId,
            Long salidaId, String estado, Integer pagina, Integer tamano, Object datos,
            SessionIdentity identity, RequestMetadata metadata, Class<T> responseClass) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null) {
            return PersistenceResult.error("E2_SESION_INVALIDA", "La sesión no está disponible.", 401);
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
        filtros.put("salidaId", salidaId);
        filtros.put("estado", estado);
        filtros.put("pagina", pagina);
        filtros.put("tamano", tamano);
        Map<String, Object> peticion = new LinkedHashMap<>();
        peticion.put("contexto", contexto);
        peticion.put("filtros", filtros);
        peticion.put("datos", datos == null ? Map.of() : datos);
        try {
            String payload = json.writeValueAsString(peticion);
            return jdbc.execute(connection -> {
                CallableStatement statement = connection.prepareCall(PROCEDURE);
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
                boolean success = statement.getBoolean(4);
                String message = statement.getNString(5);
                String code = statement.getString(6);
                int http = statement.getInt(7);
                if (!success) {
                    return PersistenceResult.error(code, message, http == 0 ? 400 : http);
                }
                String raw = statement.getNString(3);
                if (raw == null || raw.isBlank()) {
                    LOG.error("E2 devolvió éxito sin datos: acción={}, correlación={}", accion, metadata.correlacionId());
                    return PersistenceResult.error("E2_RESPUESTA_VACIA", "La operación no devolvió datos válidos.", 500);
                }
                T value = json.readValue(raw, responseClass);
                return PersistenceResult.ok(code, message, http == 0 ? 200 : http, value);
            });
        } catch (DataAccessException ex) {
            LOG.error("Fallo SQL E2: acción={}, correlación={}", accion, metadata.correlacionId(), ex);
            return PersistenceResult.error("E2_BD_NO_DISPONIBLE", "No se pudo completar la operación en la base de datos.", 503);
        } catch (RuntimeException ex) {
            LOG.error("Contrato E2 inválido: acción={}, correlación={}", accion, metadata.correlacionId(), ex);
            return PersistenceResult.error("E2_CONTRATO_INVALIDO", "Los datos de la operación no cumplen el contrato esperado.", 500);
        }
    }

    private <T> PersistenceResult<T> call(String accion, Long uot, Long convenio, Long id,
            Object datos, SessionIdentity identity, RequestMetadata metadata, Class<T> responseClass) {
        return ejecutar(accion, uot, convenio, id, null, null, null, datos, identity, metadata, responseClass);
    }

    @Override public PersistenceResult<E2Models.ListResult> listar(E2Commands.Listar c, SessionIdentity i, RequestMetadata m) {
        return ejecutar("LISTAR", c.uotId(), c.convenioId(), null, c.estado(), c.pagina(), c.tamano(), null, i, m, E2Models.ListResult.class);
    }
    @Override public PersistenceResult<E2Models.Catalogs> catalogos(E2Commands.Catalogos c, SessionIdentity i, RequestMetadata m) {
        return call("CATALOGOS", c.uotId(), c.convenioId(), null, null, i, m, E2Models.Catalogs.class);
    }
    @Override public PersistenceResult<E2Models.Detail> ver(E2Commands.Ver c, SessionIdentity i, RequestMetadata m) {
        return call("VER", c.uotId(), c.convenioId(), c.salidaId(), null, i, m, E2Models.Detail.class);
    }
    @Override public PersistenceResult<E2Models.Operation> solicitar(E2Commands.Solicitar c, SessionIdentity i, RequestMetadata m) {
        return call("SOLICITAR", c.uotId(), c.convenioId(), null, c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> corregir(E2Commands.Corregir c, SessionIdentity i, RequestMetadata m) {
        return call("CORREGIR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> decidir(E2Commands.Decidir c, SessionIdentity i, RequestMetadata m) {
        return call("DECIDIR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> entregar(E2Commands.Entregar c, SessionIdentity i, RequestMetadata m) {
        return call("ENTREGAR", c.uotId(), c.convenioId(), c.salidaId(), null, i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> iniciar(E2Commands.Iniciar c, SessionIdentity i, RequestMetadata m) {
        return call("INICIAR", c.uotId(), c.convenioId(), c.salidaId(), null, i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> visitar(E2Commands.Visitar c, SessionIdentity i, RequestMetadata m) {
        return call("VISITAR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> finalizarVisita(E2Commands.FinalizarVisita c, SessionIdentity i, RequestMetadata m) {
        Map<String, Object> datos = new LinkedHashMap<>();
        datos.put("visitaId", c.visitaId());
        if (c.datos() != null) {
            datos.put("resumen", c.datos().resumen());
            datos.put("recomendaciones", c.datos().recomendaciones());
        }
        return call("FINALIZAR_VISITA", c.uotId(), c.convenioId(), c.salidaId(), datos, i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> retornar(E2Commands.Retornar c, SessionIdentity i, RequestMetadata m) {
        return call("RETORNAR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> inspeccionar(E2Commands.Inspeccionar c, SessionIdentity i, RequestMetadata m) {
        return call("INSPECCIONAR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> regularizarFin(E2Commands.RegularizarFin c, SessionIdentity i, RequestMetadata m) {
        return call("REGULARIZAR_FIN", c.uotId(), c.convenioId(), c.salidaId(), Map.of("fechaFinPrevista", c.fechaFinPrevista()), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> cerrar(E2Commands.Cerrar c, SessionIdentity i, RequestMetadata m) {
        return call("CERRAR", c.uotId(), c.convenioId(), c.salidaId(), c.datos(), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> vincularDestino(E2Commands.VincularDestino c, SessionIdentity i, RequestMetadata m) {
        return call("VINCULAR_DESTINO", c.uotId(), c.convenioId(), c.salidaId(), Map.of("destinoId", c.destinoId(), "predioId", c.predioId()), i, m, E2Models.Operation.class);
    }
    @Override public PersistenceResult<E2Models.Operation> cancelar(E2Commands.Cancelar c, SessionIdentity i, RequestMetadata m) {
        return call("CANCELAR", c.uotId(), c.convenioId(), c.salidaId(), Map.of("motivo", c.motivo() == null ? "" : c.motivo()), i, m, E2Models.Operation.class);
    }
}
