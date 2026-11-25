package com.franco.desco.adapter.out.sqlserver.expediente;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;
import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.expediente.port.out.E1PersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.expediente.E1Models;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.CallableStatementCreator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.CallableStatement;
import java.sql.Types;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class E1SqlServerAdapter implements E1PersistencePort {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(E1SqlServerAdapter.class);
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E1SqlServerAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public PersistenceResult<E1Models.Convenios> listConvenios(E1Commands.ListConvenios c, SessionIdentity i, RequestMetadata m) {
        return execute("CONVENIOS", c.uotId(), null, null, null, null, i, m, E1Models.Convenios.class);
    }

    @Override
    public PersistenceResult<E1Models.Personas> searchPersonas(E1Commands.SearchPersonas c, SessionIdentity i, RequestMetadata m) {
        return execute("PERSONAS", c.uotId(), null, null, c.buscar(), null, i, m, E1Models.Personas.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> createPersona(E1Commands.CreatePersona c, SessionIdentity i, RequestMetadata m) {
        return execute("PERSONA_CREAR", c.uotId(), null, null, null, c.persona(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Predios> listPredios(E1Commands.ListPredios c, SessionIdentity i, RequestMetadata m) {
        return execute("PREDIOS", c.uotId(), c.convenioId(), null, c.buscar(), null, i, m, E1Models.Predios.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> createPredio(E1Commands.CreatePredio c, SessionIdentity i, RequestMetadata m) {
        return execute("PREDIO_CREAR", c.uotId(), c.convenioId(), null, null, c.predio(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Expediente> getExpediente(E1Commands.GetExpediente c, SessionIdentity i, RequestMetadata m) {
        return execute("EXPEDIENTE", c.uotId(), c.convenioId(), c.predioId(), null, null, i, m, E1Models.Expediente.class);
    }

    @Override
    public PersistenceResult<E1Models.Catalogos> getCatalogos(E1Commands.GetCatalogos c, SessionIdentity i, RequestMetadata m) {
        return execute("CATALOGOS", c.uotId(), null, null, null, null, i, m, E1Models.Catalogos.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> addCultivo(E1Commands.AddCultivo c, SessionIdentity i, RequestMetadata m) {
        return execute("CULTIVO_CREAR", c.uotId(), c.convenioId(), c.predioId(), null, c.cultivo(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> addCrianza(E1Commands.AddCrianza c, SessionIdentity i, RequestMetadata m) {
        return execute("CRIANZA_CREAR", c.uotId(), c.convenioId(), c.predioId(), null, c.crianza(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> addConteo(E1Commands.AddConteo c, SessionIdentity i, RequestMetadata m) {
        return execute("CONTEO_CREAR", c.uotId(), c.convenioId(), c.predioId(), null, c.conteo(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> addActuacion(E1Commands.AddActuacion c, SessionIdentity i, RequestMetadata m) {
        return execute("ACTUACION_CREAR", c.uotId(), c.convenioId(), c.predioId(), null, c.actuacion(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> completeFicha(E1Commands.CompleteFicha c, SessionIdentity i, RequestMetadata m) {
        return execute("FICHA_COMPLETAR", c.uotId(), c.convenioId(), c.predioId(), null, c.ficha(), i, m, E1Models.Identificador.class);
    }

    @Override
    public PersistenceResult<E1Models.Identificador> linkConvenio(E1Commands.LinkConvenio c, SessionIdentity i, RequestMetadata m) {
        return execute("AMBITO_VINCULAR", c.uotId(), c.convenioId(), c.predioId(), null, c.vinculo(), i, m, E1Models.Identificador.class);
    }

    private <T> PersistenceResult<T> execute(String action, Long uotId, Long convenioId, Long predioId,
                                              String search, Object data, SessionIdentity identity,
                                              RequestMetadata meta, Class<T> resultType) {
        if (identity == null || identity.sesionPublicaId() == null) {
            return PersistenceResult.error("SESION_INVALIDA", "La sesión no es válida o ha expirado.", 401);
        }
        try {
            Map<String, Object> filtros = new LinkedHashMap<>();
            filtros.put("uotId", uotId);
            filtros.put("convenioId", convenioId);
            filtros.put("predioId", predioId);
            filtros.put("buscar", search);
            Map<String, Object> base = new LinkedHashMap<>();
            base.put("filtros", filtros);
            base.put("datos", data);
            String contenido = json.writeValueAsString(base);
            String huella = sha256(action + ":" + contenido);
            Map<String, Object> contexto = new LinkedHashMap<>();
            contexto.put("sesionPublicaId", identity.sesionPublicaId());
            contexto.put("correlacionId", meta.correlacionId());
            contexto.put("solicitudId", meta.solicitudId());
            contexto.put("claveIdempotencia", meta.claveIdempotencia());
            contexto.put("requestHashHex", huella);
            contexto.put("ip", meta.ip());
            contexto.put("endpoint", meta.endpoint());
            base.put("contexto", contexto);
            String entrada = json.writeValueAsString(base);
            PersistenceResult<T> result = PaTrace.call("prod.PA_ExpedienteProductivo_Ejecutar", action, () -> jdbc.execute((CallableStatementCreator) connection -> {
                CallableStatement statement = connection.prepareCall("{call prod.PA_ExpedienteProductivo_Ejecutar(?,?,?,?,?,?,?)}");
                statement.setString(1, action);
                statement.setNString(2, entrada);
                // The populated dossier can exceed the 4000-character NVARCHAR output buffer.
                statement.registerOutParameter(3, Types.LONGNVARCHAR);
                statement.registerOutParameter(4, Types.BIT);
                statement.registerOutParameter(5, Types.NVARCHAR);
                statement.registerOutParameter(6, Types.VARCHAR);
                statement.registerOutParameter(7, Types.SMALLINT);
                return statement;
            }, (CallableStatementCallback<PersistenceResult<T>>) statement -> {
                statement.execute();
                boolean ok = statement.getBoolean(4);
                String raw = statement.getNString(3);
                T value = null;
                if (ok && raw != null) {
                    try { value = json.readValue(raw, resultType); }
                    catch (JacksonException parseError) { throw new java.sql.SQLException("Respuesta inválida del procedimiento", parseError); }
                }
                return new PersistenceResult<>(ok, statement.getString(6), statement.getNString(5),
                        (int) statement.getShort(7), value);
            }));
            if (!result.exitoso() && result.httpSugerido() >= 500) {
                logTechnicalFailure(action, meta.correlacionId());
                return PersistenceResult.error(result.codigo(),
                        "No se pudo completar la operación. Intente nuevamente.", result.httpSugerido());
            }
            return result;
        } catch (Exception error) {
            log.error("Error de expediente: accion={}, correlacion={}", action, meta.correlacionId(), error);
            return PersistenceResult.error("EXPEDIENTE_SQL_ERROR",
                    "No se pudo completar la operación; revise el contexto y vuelva a intentar.", 503);
        }
    }

    /** Consulta la auditoría únicamente cuando SQL devolvió un error técnico. */
    private void logTechnicalFailure(String action, java.util.UUID correlationId) {
        if (correlationId == null) {
            log.error(">> [PA ERROR SQL/TECNICO] procedimiento=prod.PA_ExpedienteProductivo_Ejecutar accion={} auditoria=sin-correlacion", action);
            return;
        }
        try {
            var errors = jdbc.query(
                    "SELECT TOP (1) numero_sql, procedimiento, linea_sql, mensaje_sql "
                            + "FROM auditoria.ExpedienteErrorTecnico WITH (NOLOCK) "
                            + "WHERE correlacion_id=? ORDER BY error_id DESC",
                    (rs, row) -> new SqlFailure(rs.getInt("numero_sql"),
                            rs.getString("procedimiento"), rs.getInt("linea_sql"),
                            rs.getString("mensaje_sql")), correlationId);
            if (errors.isEmpty()) {
                log.error(">> [PA ERROR SQL/TECNICO] procedimiento=prod.PA_ExpedienteProductivo_Ejecutar accion={} correlacionId={} auditoria=sin-registro",
                        action, correlationId);
            } else {
                SqlFailure failure = errors.getFirst();
                log.error(">> [PA ERROR SQL/TECNICO] procedimiento=prod.PA_ExpedienteProductivo_Ejecutar accion={} correlacionId={} codigoSQL={} origen={} linea={} detalle={}",
                        action, correlationId, failure.number(), failure.procedure(), failure.line(), failure.message());
            }
        } catch (org.springframework.dao.DataAccessException auditError) {
            log.error(">> [PA ERROR SQL/TECNICO] procedimiento=prod.PA_ExpedienteProductivo_Ejecutar accion={} correlacionId={} auditoria=no-disponible tipo={}",
                    action, correlationId, auditError.getClass().getSimpleName());
        }
    }

    private record SqlFailure(int number, String procedure, int line, String message) {}

    private static String sha256(String text) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(text.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.NoSuchAlgorithmException error) {
            throw new IllegalStateException("SHA-256 no disponible", error);
        }
    }
}
