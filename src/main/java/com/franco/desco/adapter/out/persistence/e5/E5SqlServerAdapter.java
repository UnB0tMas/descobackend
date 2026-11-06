package com.franco.desco.adapter.out.persistence.e5;

import com.franco.desco.application.e5.E5Commands;
import com.franco.desco.application.e5.port.out.E5PersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.json.JsonMapper;
import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Repository("e5PersistenceSqlServerAdapter")
@Primary
public final class E5SqlServerAdapter implements E5PersistencePort {
    private static final String CALL="{call finanzas.PA_APAPPSS_E5_Ejecutar(?,?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    public E5SqlServerAdapter(JdbcTemplate jdbc,JsonMapper json) { this.jdbc=jdbc;this.json=json; }
    @Override public <T> PersistenceResult<T> execute(E5Commands.Execute command,SessionIdentity identity,
                                                        RequestMetadata metadata,Class<T> type) {
        if (identity==null || identity.sesionPublicaId()==null || metadata==null)
            return PersistenceResult.error("E5_SESION_INVALIDA","La sesión no está disponible.",401);
        Map<String,Object> contexto=new LinkedHashMap<>();
        contexto.put("sesionPublicaId",identity.sesionPublicaId());
        contexto.put("correlacionId",metadata.correlacionId());
        contexto.put("solicitudId",metadata.solicitudId());
        contexto.put("claveIdempotencia",metadata.claveIdempotencia());
        contexto.put("ip",metadata.ip());contexto.put("endpoint",metadata.endpoint());
        contexto.put("userAgent",metadata.userAgent());contexto.put("deviceId",metadata.deviceId());
        Map<String,Object> filtros=new LinkedHashMap<>();
        filtros.put("campaniaId",command.campaniaId());filtros.put("gastoId",command.gastoId());
        filtros.put("participacionId",command.participacionId());filtros.put("liquidacionId",command.liquidacionId());
        filtros.put("pagoId",command.pagoId());
        Map<String,Object> payload=new LinkedHashMap<>();
        payload.put("contexto",contexto);payload.put("filtros",filtros);
        payload.put("datos",command.datos()==null?Map.of():command.datos());
        String raw=json.writeValueAsString(payload);
        try {
            return jdbc.execute(connection->{
                CallableStatement stmt=connection.prepareCall(CALL);
                stmt.setString(1,command.accion());stmt.setNString(2,raw);
                stmt.registerOutParameter(3,Types.LONGNVARCHAR);
                stmt.registerOutParameter(4,Types.BIT);
                stmt.registerOutParameter(5,Types.NVARCHAR);
                stmt.registerOutParameter(6,Types.VARCHAR);
                stmt.registerOutParameter(7,Types.SMALLINT);
                return stmt;
            },(CallableStatement stmt)->{
                stmt.execute();int http=stmt.getInt(7);
                if (!stmt.getBoolean(4)) return PersistenceResult.error(stmt.getString(6),stmt.getNString(5),
                    http==0?400:http);
                String value=stmt.getNString(3);
                T parsed=value==null||value.isBlank()?null:json.readValue(value,type);
                return PersistenceResult.ok(stmt.getString(6),stmt.getNString(5),http==0?200:http,parsed);
            });
        } catch (DataAccessException ex) {
            return PersistenceResult.error("E5_BD_NO_DISPONIBLE",
                "La operación financiera no pudo completarse en este momento.",503);
        }
    }
}
