package com.franco.desco.adapter.out.sqlserver.uot;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotLifecycleCommands;
import com.franco.desco.application.uot.port.out.UotLifecyclePersistencePort;
import com.franco.desco.domain.uot.UotLifecycleModels;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Types;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class UotLifecycleSqlServerAdapter implements UotLifecyclePersistencePort {
    private final SimpleJdbcCall impact;
    private final SimpleJdbcCall transfer;
    private final SimpleJdbcCall deactivate;

    public UotLifecycleSqlServerAdapter(DataSource dataSource) {
        this.impact = call(dataSource,"org","PA_UOT_Sel_ImpactoBaja",
                in("nUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),
                outInt("nUotIncluidas"),outInt("nUsuariosActivos"),outInt("nUsuariosExclusivos"),outInt("nEmpleadosActivos"),
                outInt("nAreasActivas"),outInt("nOrganizacionesActivas"),outInt("nPrediosActivos"),outInt("nAlmacenesActivos"),
                outInt("nProductosConStock"),outInt("nStockReservado"),outInt("nSuministrosConStock"),outInt("nSuministrosReservados"),
                outInt("nBienesActivos"),outInt("nVentasAbiertas"),outInt("nCampaniasAbiertas"),outInt("nOperativosAbiertos"),outInt("nSalidasAbiertas"),outInt("nRecursosAbiertos"),
                new SqlOutParameter("bPuedeDeshabilitar",Types.BIT),commonResult(),commonMessage(),commonCode(),commonHttp());
        this.transfer = call(dataSource,"logistica","PA_UOT_Ins_TransferirRecursos",
                in("nUsuarioId",Types.BIGINT),in("nUotOrigenId",Types.BIGINT),in("nUotDestinoId",Types.BIGINT),
                in("nAlmacenOrigenId",Types.BIGINT),in("nAlmacenDestinoId",Types.BIGINT),in("bTransferirStock",Types.BIT),
                in("cBienesJson",Types.NVARCHAR),in("cSuministrosJson",Types.NVARCHAR),in("gClaveIdempotencia",Types.OTHER),in("cMotivo",Types.NVARCHAR),
                new SqlOutParameter("nMovimientoSalidaId",Types.BIGINT),new SqlOutParameter("nMovimientoEntradaId",Types.BIGINT),
                outInt("nProductosTransferidos"),outInt("nBienesTransferidos"),outInt("nSuministrosTransferidos"),
                commonResult(),commonMessage(),commonCode(),commonHttp());
        this.deactivate = call(dataSource,"org","PA_UOT_Upd_Deshabilitar",
                in("nUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("cMotivo",Types.NVARCHAR),commonResult(),commonMessage(),commonCode(),commonHttp());
    }

    @Override
    public PersistenceResult<UotLifecycleModels.DeactivationImpact> impact(UotLifecycleCommands.Impact c, SessionIdentity i) {
        Map<String,Object> o=impact.execute(new MapSqlParameterSource().addValue("nUsuarioId",i.usuarioId()).addValue("nUotId",c.uotId()));
        if(!ok(o)) return error(o);
        return PersistenceResult.ok(code(o),message(o),http(o),new UotLifecycleModels.DeactivationImpact(
                c.uotId(),num(o,"nUotIncluidas"),num(o,"nUsuariosActivos"),num(o,"nUsuariosExclusivos"),num(o,"nEmpleadosActivos"),
                num(o,"nAreasActivas"),num(o,"nOrganizacionesActivas"),num(o,"nPrediosActivos"),num(o,"nAlmacenesActivos"),
                num(o,"nProductosConStock"),num(o,"nStockReservado"),num(o,"nSuministrosConStock"),num(o,"nSuministrosReservados"),
                num(o,"nBienesActivos"),num(o,"nVentasAbiertas"),num(o,"nCampaniasAbiertas"),num(o,"nOperativosAbiertos"),num(o,"nSalidasAbiertas"),num(o,"nRecursosAbiertos"),bool(o,"bPuedeDeshabilitar")));
    }

    @Override
    public PersistenceResult<UotLifecycleModels.ResourceTransfer> transfer(UotLifecycleCommands.TransferResources c, SessionIdentity i) {
        String assets=json(c.assetIds());
        String supplies=json(c.supplyIds());
        Map<String,Object> o=transfer.execute(new MapSqlParameterSource()
                .addValue("nUsuarioId",i.usuarioId()).addValue("nUotOrigenId",c.sourceUotId()).addValue("nUotDestinoId",c.targetUotId())
                .addValue("nAlmacenOrigenId",c.sourceWarehouseId()).addValue("nAlmacenDestinoId",c.targetWarehouseId()).addValue("bTransferirStock",c.transferStock())
                .addValue("cBienesJson",assets).addValue("cSuministrosJson",supplies).addValue("gClaveIdempotencia",c.idempotencyKey()).addValue("cMotivo",c.reason()));
        if(!ok(o)) return error(o);
        return PersistenceResult.ok(code(o),message(o),http(o),new UotLifecycleModels.ResourceTransfer(
                longValue(o,"nMovimientoSalidaId"),longValue(o,"nMovimientoEntradaId"),num(o,"nProductosTransferidos"),num(o,"nBienesTransferidos"),num(o,"nSuministrosTransferidos")));
    }

    @Override
    public PersistenceResult<Void> deactivate(UotLifecycleCommands.Deactivate c, SessionIdentity i) {
        Map<String,Object> o=deactivate.execute(new MapSqlParameterSource().addValue("nUsuarioId",i.usuarioId()).addValue("nUotId",c.uotId()).addValue("cMotivo",c.reason()));
        return ok(o)?PersistenceResult.ok(code(o),message(o),http(o),null):error(o);
    }

    private static String json(java.util.List<Long> ids){return "["+ids.stream().map(String::valueOf).collect(Collectors.joining(","))+"]";}
    private static SimpleJdbcCall call(DataSource d,String schema,String name,org.springframework.jdbc.core.SqlParameter... p){return new SimpleJdbcCall(d).withSchemaName(schema).withProcedureName(name).withoutProcedureColumnMetaDataAccess().declareParameters(p);}
    private static SqlParameter in(String n,int t){return new SqlParameter(n,t);}
    private static SqlOutParameter outInt(String n){return new SqlOutParameter(n,Types.INTEGER);}
    private static SqlOutParameter commonResult(){return new SqlOutParameter("bResultado",Types.BIT);}
    private static SqlOutParameter commonMessage(){return new SqlOutParameter("cMensaje",Types.NVARCHAR);}
    private static SqlOutParameter commonCode(){return new SqlOutParameter("cCodigoRespuesta",Types.VARCHAR);}
    private static SqlOutParameter commonHttp(){return new SqlOutParameter("nHttpRespuesta",Types.SMALLINT);}
    private static boolean ok(Map<String,Object> o){return bool(o,"bResultado");}
    private static boolean bool(Map<String,Object> o,String k){Object v=o.get(k);return v instanceof Boolean b?b:v instanceof Number n&&n.intValue()!=0;}
    private static int num(Map<String,Object> o,String k){Object v=o.get(k);return v instanceof Number n?n.intValue():0;}
    private static Long longValue(Map<String,Object> o,String k){Object v=o.get(k);return v instanceof Number n?n.longValue():null;}
    private static String message(Map<String,Object> o){Object v=o.get("cMensaje");return v==null?null:v.toString();}
    private static String code(Map<String,Object> o){Object v=o.get("cCodigoRespuesta");return v==null?null:v.toString();}
    private static Integer http(Map<String,Object> o){Object v=o.get("nHttpRespuesta");return v instanceof Number n?n.intValue():null;}
    private static <T> PersistenceResult<T> error(Map<String,Object> o){return PersistenceResult.error(code(o),message(o),http(o));}
}
