package com.franco.desco.adapter.out.persistence.planta.registro;

import com.franco.desco.application.shared.*;
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

/** Dos consultas especializadas; cada invocación apunta a un único PA específico. */
@Repository
public class E3RegistroPersistence {
 private static final Logger log=LoggerFactory.getLogger(E3RegistroPersistence.class);
 private final JdbcTemplate jdbc;
 private final JsonMapper json;
 public E3RegistroPersistence(JdbcTemplate jdbc,JsonMapper json){this.jdbc=jdbc;this.json=json;}
 public <T> PersistenceResult<T> ejecutar(String procedimiento,Long uotId,Long convenioId,Long predioId,
    Object datos,SessionIdentity identidad,RequestMetadata meta,Class<T> tipo){
  if(identidad==null||identidad.sesionPublicaId()==null||meta==null)
   return PersistenceResult.error("E3_SESION","La sesión no está disponible.",401);
  if(!"prod.PA_E3_Planta_Sel_AltaInicial".equals(procedimiento)
     &&!"prod.PA_E3_Planta_Ins_Individual".equals(procedimiento))
   throw new IllegalArgumentException("Procedimiento no permitido");
  Map<String,Object> contexto=new LinkedHashMap<>();
  contexto.put("sesionPublicaId",identidad.sesionPublicaId());
  contexto.put("correlacionId",meta.correlacionId());
  contexto.put("solicitudId",meta.solicitudId());
  contexto.put("claveIdempotencia",meta.claveIdempotencia());
  contexto.put("ip",meta.ip());
  contexto.put("endpoint",meta.endpoint());
  contexto.put("userAgent",meta.userAgent());
  contexto.put("deviceId",meta.deviceId());
  String payload=json.writeValueAsString(Map.of("contexto",contexto,
    "filtros",Map.of("uotId",uotId,"convenioId",convenioId,"predioId",predioId),
    "datos",datos==null?Map.of():datos));
  try{
   return jdbc.execute(conexion->{
    CallableStatement s=conexion.prepareCall("{call "+procedimiento+"(?,?,?,?,?,?)}");
    s.setNString(1,payload);
    s.registerOutParameter(2,Types.LONGNVARCHAR);
    s.registerOutParameter(3,Types.BIT);
    s.registerOutParameter(4,Types.NVARCHAR);
    s.registerOutParameter(5,Types.VARCHAR);
    s.registerOutParameter(6,Types.SMALLINT);
    return s;
   },(CallableStatement s)->{
    s.execute();
    String raw=s.getNString(2);
    if(!s.getBoolean(3))return PersistenceResult.error(s.getString(5),s.getNString(4),s.getInt(6));
    T objeto=(raw==null||raw.isBlank())?null:json.readValue(raw,tipo);
    return PersistenceResult.ok(s.getString(5),s.getNString(4),s.getInt(6),objeto);
   });
  }catch(DataAccessException e){
   log.error("E3 [{}] fallo de SQL uot={} convenio={} predio={} corr={}",procedimiento,uotId,convenioId,predioId,meta.correlacionId(),e);
   return PersistenceResult.error("E3_BD","No fue posible completar la operación.",503);
  }
 }
}
