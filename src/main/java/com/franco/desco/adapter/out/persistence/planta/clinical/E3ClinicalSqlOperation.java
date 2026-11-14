package com.franco.desco.adapter.out.persistence.planta.clinical;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/** Transporte SQL compartido: cada repositorio concreto ejecuta exclusivamente su propio PA. */
abstract class E3ClinicalSqlOperation implements E3ClinicalOperation {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;
    private final String key;
    private final String procedure;

    protected E3ClinicalSqlOperation(JdbcTemplate jdbc,JsonMapper json,String key,String procedure) {
        this.jdbc=jdbc;this.json=json;this.key=key;this.procedure=procedure;
    }
    @Override public String key(){return key;}
    @Override public final PersistenceResult<Object> execute(long uotId,long convenioId,long predioId,Long parcelaCultivoId,long plantaId,
       Long episodioId,Object datos,SessionIdentity identity,RequestMetadata metadata) {
        if(identity==null||identity.sesionPublicaId()==null||metadata==null)
            return PersistenceResult.error("E3_SESION_INVALIDA","La sesión no está disponible.",401);
        Map<String,Object> contexto=new LinkedHashMap<>();
        contexto.put("sesionPublicaId",identity.sesionPublicaId());
        contexto.put("correlacionId",metadata.correlacionId());
        contexto.put("solicitudId",metadata.solicitudId());
        contexto.put("claveIdempotencia",metadata.claveIdempotencia());
        contexto.put("ip",metadata.ip());
        contexto.put("endpoint",metadata.endpoint());
        contexto.put("userAgent",metadata.userAgent());
        contexto.put("deviceId",metadata.deviceId());
        Map<String,Object> filtros=new LinkedHashMap<>();
        filtros.put("uotId",uotId);filtros.put("convenioId",convenioId);
        filtros.put("predioId",predioId);filtros.put("parcelaCultivoId",parcelaCultivoId);filtros.put("plantaId",plantaId);
        filtros.put("episodioId",episodioId);
        Map<String,Object> peticion=Map.of("contexto",contexto,"filtros",filtros,"datos",datos==null?Map.of():datos);
        String payload=json.writeValueAsString(peticion);
        try {
            return jdbc.execute((ConnectionCallback<PersistenceResult<Object>>) connection -> {
                try(CallableStatement call=connection.prepareCall("{call "+procedure+"(?,?,?,?,?,?)}")) {
                    call.setNString(1,payload);
                    call.registerOutParameter(2,Types.LONGNVARCHAR);
                    call.registerOutParameter(3,Types.BIT);
                    call.registerOutParameter(4,Types.NVARCHAR);
                    call.registerOutParameter(5,Types.VARCHAR);
                    call.registerOutParameter(6,Types.SMALLINT);
                    call.execute();
                    boolean ok=call.getBoolean(3);
                    String code=call.getString(5),message=call.getNString(4);
                    int http=call.getInt(6);
                    if(!ok)return PersistenceResult.error(code,message,http==0?400:http);
                    String raw=call.getNString(2);
                    Object value=raw==null||raw.isBlank()?null:json.readValue(raw,Object.class);
                    return PersistenceResult.ok(code,message,http==0?200:http,value);
                }
            });
        }catch(DataAccessException ex){
            return PersistenceResult.error("E3_BD_NO_DISPONIBLE","No fue posible completar la operación.",503);
        }
    }
}
