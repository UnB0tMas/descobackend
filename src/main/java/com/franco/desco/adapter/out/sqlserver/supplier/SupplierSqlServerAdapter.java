package com.franco.desco.adapter.out.sqlserver.supplier;

import com.franco.desco.adapter.out.sql.common.SqlProcedureExecutor;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.supplier.port.out.SupplierPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository
public final class SupplierSqlServerAdapter implements SupplierPersistencePort {
    private static final Logger LOG = LoggerFactory.getLogger(SupplierSqlServerAdapter.class);
    private final SqlProcedureExecutor procedures;
    private final JsonMapper json;
    public SupplierSqlServerAdapter(SqlProcedureExecutor procedures, JsonMapper json) {
        this.procedures = procedures; this.json = json;
    }

    @Override
    public <T> PersistenceResult<T> execute(String action, Long uotId, Object data,
                                            SessionIdentity identity, Class<T> resultType) {
        long started = System.nanoTime();
        String name = "org.PA_ProveedorUOT_Ejecutar";
        LOG.info(">> PA INICIO nombre={} accion={}", name, action);
        try {
            Map<String, Object> args = new LinkedHashMap<>();
            args.put("cAccion", action);
            args.put("nUsuarioId", identity.usuarioId());
            args.put("nUotId", uotId);
            args.put("cJson", json.writeValueAsString(data));
            Map<String, Object> out = procedures.call("org", "PA_ProveedorUOT_Ejecutar", args,
                new SqlParameter("cAccion", Types.VARCHAR),
                new SqlParameter("nUsuarioId", Types.BIGINT),
                new SqlParameter("nUotId", Types.BIGINT),
                new SqlParameter("cJson", Types.NVARCHAR),
                new SqlOutParameter("cDatos", Types.LONGNVARCHAR),
                new SqlOutParameter("bResultado", Types.BIT),
                new SqlOutParameter("cMensaje", Types.NVARCHAR),
                new SqlOutParameter("cCodigo", Types.VARCHAR),
                new SqlOutParameter("nHttp", Types.SMALLINT));
            String msg = SqlProcedureExecutor.message(out, "No se pudo completar la operación.");
            String code = out.get("cCodigo") == null ? null : out.get("cCodigo").toString();
            int http = out.get("nHttp") instanceof Number n ? n.intValue() : 400;
            long duration = (System.nanoTime() - started) / 1_000_000;
            if (!SqlProcedureExecutor.success(out)) {
                LOG.warn(">> PA ERROR FUNCIONAL nombre={} accion={} codigo={} http={} descripcion={} duracionMs={}",
                    name, action, code, http, msg, duration);
                return PersistenceResult.error(code, msg, http);
            }
            T parsed = null;
            Object raw = out.get("cDatos");
            if (raw != null) parsed = json.readValue(raw.toString(), resultType);
            LOG.info(">> PA EXITOSO nombre={} accion={} codigo={} http={} descripcion={} duracionMs={}",
                name, action, code, http, msg, duration);
            return PersistenceResult.ok(code, msg, http, parsed);
        } catch (Exception ex) {
            LOG.error(">> PA ERROR SQL/TECNICO nombre={} accion={} duracionMs={}",
                name, action, (System.nanoTime() - started) / 1_000_000, ex);
            return PersistenceResult.error("PROVEEDOR_ERROR", "No se pudo completar la operación.", 503);
        }
    }
}
