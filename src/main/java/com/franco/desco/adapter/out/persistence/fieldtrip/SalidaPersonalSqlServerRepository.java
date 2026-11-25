package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.fieldtrip.personal.port.out.SalidaPersonalPersistencePort;
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
import java.util.Map;

@Repository
public class SalidaPersonalSqlServerRepository implements SalidaPersonalPersistencePort {
    private static final Logger LOG=LoggerFactory.getLogger(SalidaPersonalSqlServerRepository.class);
    private static final String PA="{call campo.PA_SalidaPersonal_Consultar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public SalidaPersonalSqlServerRepository(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc=jdbc;
        this.json=json;
    }

    @Override
    public <T> PersistenceResult<T> consultar(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata, Class<T> resultType) {
        if (identity == null || identity.sesionPublicaId() == null || metadata == null)
            return PersistenceResult.error("SALIDA_PERSONAL_SESION", "Inicie sesión nuevamente.", 401);

        Map<String,Object> contexto=new LinkedHashMap<>();
        contexto.put("sesionPublicaId", identity.sesionPublicaId());
        contexto.put("correlacionId", metadata.correlacionId());
        contexto.put("solicitudId", metadata.solicitudId());
        contexto.put("ip", metadata.ip());
        contexto.put("endpoint", metadata.endpoint());
        contexto.put("userAgent", metadata.userAgent());
        contexto.put("deviceId", metadata.deviceId());
        Map<String,Object> filtros=new LinkedHashMap<>();
        filtros.put("uotId",query.uotId());
        filtros.put("salidaId",query.salidaId());
        filtros.put("buscar",query.buscar());
        filtros.put("estado",query.estado());
        filtros.put("pagina",query.pagina());
        filtros.put("tamano",query.tamano());
        try {
            String payload=json.writeValueAsString(Map.of("contexto",contexto,"filtros",filtros));
            return PaTrace.call(PA,query.accion(),() -> jdbc.execute(connection -> {
                CallableStatement statement=connection.prepareCall(PA);
                statement.setString(1,query.accion());
                statement.setNString(2,payload);
                statement.registerOutParameter(3,Types.LONGNVARCHAR);
                statement.registerOutParameter(4,Types.BIT);
                statement.registerOutParameter(5,Types.NVARCHAR);
                statement.registerOutParameter(6,Types.VARCHAR);
                statement.registerOutParameter(7,Types.SMALLINT);
                return statement;
            }, (CallableStatement statement) -> {
                statement.execute();
                boolean ok=statement.getBoolean(4);
                String message=statement.getNString(5);
                String code=statement.getString(6);
                int http=statement.getInt(7);
                if (!ok) return PersistenceResult.error(code,message,http==0?400:http);
                String raw=statement.getNString(3);
                if (raw==null || raw.isBlank())
                    return PersistenceResult.error("SALIDA_PERSONAL_RESPUESTA", "No se pudo consultar la salida.",500);
                T value=json.readValue(raw,resultType);
                return PersistenceResult.ok(code,message,http==0?200:http,value);
            }));
        } catch (DataAccessException ex) {
            LOG.error("Consulta de salida E2 falló: acción={}, correlación={}",query.accion(),metadata.correlacionId(),ex);
            return PersistenceResult.error("SALIDA_PERSONAL_SQL", "No se pudo consultar la salida.",503);
        } catch (RuntimeException ex) {
            LOG.error("Contrato de salida personal inválido: acción={}, correlación={}",query.accion(),metadata.correlacionId(),ex);
            return PersistenceResult.error("SALIDA_PERSONAL_CONTRATO", "No se pudo consultar la salida.",500);
        }
    }
}
