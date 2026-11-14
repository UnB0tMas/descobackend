package com.franco.desco.adapter.out.persistence.e5;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.CallableStatement;
import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

/** Un procedimiento independiente para cada responsabilidad financiera nueva. */
@Repository
public class E5ExtrasSqlServerAdapter {
    private static final String GRAFICOS="{call finanzas.PA_E5_Graficos_Sel_Indicadores(?,?,?,?,?,?)}";
    private static final String BENEFICIARIO="{call finanzas.PA_E5_Beneficiario_Sel_Liquidacion(?,?,?,?,?,?)}";
    private static final String ENTREGAS="{call finanzas.PA_E5_EntregasSocio_Sel_Detalle(?,?,?,?,?,?)}";
    private static final String COBROS_DETALLE="{call finanzas.PA_E5_CobrosCampania_Sel_Detalle(?,?,?,?,?,?)}";
    private static final String PAGO="{call finanzas.PA_E5_PagoBeneficiario_Ins_Confirmado(?,?,?,?,?,?)}";
    private static final String RECEPTOR="{call finanzas.PA_E5_Receptor_InsOGet(?,?,?,?,?,?)}";
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public E5ExtrasSqlServerAdapter(JdbcTemplate jdbc,JsonMapper json) {
        this.jdbc=jdbc;
        this.json=json;
    }

    public <T> PersistenceResult<T> execute(String operacion,Long campaniaId,Long liquidacionId,
        Map<String,Object> datos,SessionIdentity identity,RequestMetadata metadata,Class<T> type) {
        if(identity==null || identity.sesionPublicaId()==null || metadata==null)
            return PersistenceResult.error("E5_SESION_INVALIDA","La sesión no está disponible.",401);
        String call=switch(operacion) {
            case "GRAFICOS" -> GRAFICOS;
            case "ENTREGAS" -> ENTREGAS;
            case "COBROS_DETALLE" -> COBROS_DETALLE;
            case "BENEFICIARIO" -> BENEFICIARIO;
            case "PAGAR" -> PAGO;
            case "RECEPTOR" -> RECEPTOR;
            default -> throw new IllegalArgumentException("Operación financiera inválida");
        };
        Map<String,Object> contexto=new LinkedHashMap<>();
        contexto.put("sesionPublicaId",identity.sesionPublicaId());
        contexto.put("correlacionId",metadata.correlacionId());
        contexto.put("solicitudId",metadata.solicitudId());
        contexto.put("claveIdempotencia",metadata.claveIdempotencia());
        contexto.put("ip",metadata.ip());contexto.put("endpoint",metadata.endpoint());
        contexto.put("userAgent",metadata.userAgent());contexto.put("deviceId",metadata.deviceId());
        String payload=json.writeValueAsString(Map.of("contexto",contexto,
            "filtros",Map.of("campaniaId",campaniaId==null?0:campaniaId,
                              "liquidacionId",liquidacionId==null?0:liquidacionId),
            "datos",datos==null?Map.of():datos));
        try {
            return jdbc.execute(connection->{
                CallableStatement stmt=connection.prepareCall(call);
                stmt.setNString(1,payload);
                stmt.registerOutParameter(2,Types.LONGNVARCHAR);
                stmt.registerOutParameter(3,Types.BIT);
                stmt.registerOutParameter(4,Types.NVARCHAR);
                stmt.registerOutParameter(5,Types.VARCHAR);
                stmt.registerOutParameter(6,Types.SMALLINT);
                return stmt;
            },(CallableStatement stmt)->{
                stmt.execute();
                int status=stmt.getInt(6);
                if(!stmt.getBoolean(3))
                    return PersistenceResult.error(stmt.getString(5),stmt.getNString(4),status==0?400:status);
                String raw=stmt.getNString(2);
                T result=raw==null||raw.isBlank()?null:json.readValue(raw,type);
                return PersistenceResult.ok(stmt.getString(5),stmt.getNString(4),status==0?200:status,result);
            });
        } catch(DataAccessException ex) {
            return PersistenceResult.error("E5_EXTRAS_BD","No fue posible completar la operación financiera.",503);
        }
    }
}
