package com.franco.desco.application.supply;

import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.supply.SupplyModels;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Types;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@Service
public class SupplyUotService {
    private final SimpleJdbcCall list,create,update,movement,kardex,cancel;
    private final JdbcTemplate jdbc;

    public SupplyUotService(DataSource dataSource) {
        this.jdbc=new JdbcTemplate(dataSource);
        list=base(dataSource,"PA_SuministroUOT_Sel_Listado",
                in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("nPagina",Types.INTEGER),in("nTamano",Types.INTEGER))
                .returningResultSet("items",(rs,n)->new SupplyModels.Summary(rs.getLong("suministroId"),rs.getLong("uotId"),rs.getString("uotCodigo"),rs.getString("uotNombre"),rs.getString("codigo"),rs.getString("nombre"),rs.getString("unidadMedida"),rs.getBoolean("estado"),rs.getBigDecimal("stock"),rs.getBigDecimal("stockActual"),rs.getBigDecimal("stockReservado"),rs.getBigDecimal("stockDisponible"),rs.getBigDecimal("stockMinimo"),rs.getBoolean("requiereReposicion"),rs.getLong("totalRegistros")));
        create=base(dataSource,"PA_SuministroUOT_Ins_Registro",in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("cCodigo",Types.VARCHAR),in("cNombre",Types.NVARCHAR),in("cUnidad",Types.VARCHAR),in("nStockInicial",Types.DECIMAL),in("nStockMinimo",Types.DECIMAL),new SqlOutParameter("nSuministroId",Types.BIGINT));
        update=base(dataSource,"PA_SuministroUOT_Upd_Registro",in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("nSuministroId",Types.BIGINT),in("cNombre",Types.NVARCHAR),in("cUnidad",Types.VARCHAR),in("nStockMinimo",Types.DECIMAL));
        movement=base(dataSource,"PA_SuministroUOT_Ins_Movimiento",in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("nSuministroId",Types.BIGINT),in("cTipo",Types.VARCHAR),in("nCantidad",Types.DECIMAL),in("cDocumento",Types.NVARCHAR),in("cObservacion",Types.NVARCHAR),new SqlOutParameter("nMovimientoId",Types.BIGINT));
        kardex=base(dataSource,"PA_SuministroUOT_Sel_Kardex",in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("nSuministroId",Types.BIGINT))
                .returningResultSet("items",(rs,n)->new SupplyModels.Movement(rs.getLong("suministroMovimientoId"),rs.getLong("suministroId"),rs.getLong("uotId"),rs.getString("uotCodigo"),rs.getString("uotNombre"),rs.getString("codigo"),rs.getString("nombre"),rs.getString("unidadMedida"),(Long)rs.getObject("recursoProgramadoId"),rs.getString("tipoMovimiento"),rs.getBigDecimal("cantidad"),rs.getTimestamp("fechaHora").toInstant(),rs.getString("documentoReferencia"),rs.getString("observacion"),rs.getString("usuario"),rs.getBigDecimal("saldo")));
        cancel=base(dataSource,"PA_SuministroUOT_Upd_AnularMovimiento",in("nUsuarioId",Types.BIGINT),in("nSesionUsuarioId",Types.BIGINT),in("nUotId",Types.BIGINT),in("nMovimientoId",Types.BIGINT),in("cMotivo",Types.NVARCHAR));
    }

    @SuppressWarnings("unchecked")
    public AppResult<PageResult<SupplyModels.Summary>> list(SessionIdentity i,Long uotId,int page,int size){
        Map<String,Object> o=list.execute(params(i).addValue("nUotId",uotId).addValue("nPagina",page).addValue("nTamano",size)); if(!ok(o)) return error(o);
        List<SupplyModels.Summary> items=(List<SupplyModels.Summary>)o.getOrDefault("items",List.of()); long total=items.isEmpty()?0:items.getFirst().totalRecords(); int pages=size<=0?0:(int)Math.ceil((double)total/size);
        return AppResult.ok("SUMINISTROS_LISTADOS",message(o),new PageResult<>(items,page,size,total,pages));
    }
    public AppResult<Long> create(SessionIdentity i,Long uotId,String code,String name,String unit,java.math.BigDecimal initial,java.math.BigDecimal minimum){Map<String,Object>o=create.execute(params(i).addValue("nUotId",uotId).addValue("cCodigo",code).addValue("cNombre",name).addValue("cUnidad",unit).addValue("nStockInicial",initial).addValue("nStockMinimo",minimum==null?java.math.BigDecimal.ZERO:minimum));return ok(o)?AppResult.created(code(o),message(o),longValue(o,"nSuministroId")):error(o);}
    public AppResult<Void> update(SessionIdentity i,Long uotId,Long id,String name,String unit,java.math.BigDecimal minimum){Map<String,Object>o=update.execute(params(i).addValue("nUotId",uotId).addValue("nSuministroId",id).addValue("cNombre",name).addValue("cUnidad",unit).addValue("nStockMinimo",minimum));return ok(o)?AppResult.ok(code(o),message(o),null):error(o);}
    public AppResult<Long> movement(SessionIdentity i,Long uotId,Long id,String type,java.math.BigDecimal quantity,String document,String observation){Map<String,Object>o=movement.execute(params(i).addValue("nUotId",uotId).addValue("nSuministroId",id).addValue("cTipo",type).addValue("nCantidad",quantity).addValue("cDocumento",document).addValue("cObservacion",observation));return ok(o)?AppResult.created(code(o),message(o),longValue(o,"nMovimientoId")):error(o);}
    @SuppressWarnings("unchecked") public AppResult<List<SupplyModels.Movement>> kardex(SessionIdentity i,Long uotId,Long id){Map<String,Object>o=kardex.execute(params(i).addValue("nUotId",uotId).addValue("nSuministroId",id));return ok(o)?AppResult.ok(code(o),message(o),(List<SupplyModels.Movement>)o.getOrDefault("items",List.of())):error(o);}
    public AppResult<Void> cancel(SessionIdentity i,Long uotId,Long id,String reason){Map<String,Object>o=cancel.execute(params(i).addValue("nUotId",uotId).addValue("nMovimientoId",id).addValue("cMotivo",reason));return ok(o)?AppResult.ok(code(o),message(o),null):error(o);}

    private static SimpleJdbcCall base(DataSource d,String name,org.springframework.jdbc.core.SqlParameter... p){org.springframework.jdbc.core.SqlParameter[] all=new org.springframework.jdbc.core.SqlParameter[p.length+4];System.arraycopy(p,0,all,0,p.length);all[p.length]=new SqlOutParameter("bResultado",Types.BIT);all[p.length+1]=new SqlOutParameter("cMensaje",Types.NVARCHAR);all[p.length+2]=new SqlOutParameter("cCodigoRespuesta",Types.VARCHAR);all[p.length+3]=new SqlOutParameter("nHttpRespuesta",Types.SMALLINT);return new SimpleJdbcCall(d).withSchemaName("logistica").withProcedureName(name).withoutProcedureColumnMetaDataAccess().declareParameters(all);}
    private static SqlParameter in(String n,int t){return new SqlParameter(n,t);}
    private MapSqlParameterSource params(SessionIdentity i){Long sid=jdbc.queryForObject("SELECT sesion_usuario_id FROM seg.SesionUsuario WHERE sesion_publica_id=? AND usuario_id=? AND estado=1 AND fecha_revocacion IS NULL",Long.class,i.sesionPublicaId(),i.usuarioId());return new MapSqlParameterSource().addValue("nUsuarioId",i.usuarioId()).addValue("nSesionUsuarioId",sid);}
    private static boolean ok(Map<String,Object>o){Object v=o.get("bResultado");return v instanceof Boolean b?b:v instanceof Number n&&n.intValue()!=0;} private static String message(Map<String,Object>o){Object v=o.get("cMensaje");return v==null?null:v.toString();} private static String code(Map<String,Object>o){Object v=o.get("cCodigoRespuesta");return v==null?null:v.toString();} private static Integer http(Map<String,Object>o){Object v=o.get("nHttpRespuesta");return v instanceof Number n?n.intValue():400;} private static Long longValue(Map<String,Object>o,String k){Object v=o.get(k);return v instanceof Number n?n.longValue():null;}
    private static <T> AppResult<T> error(Map<String,Object>o){return AppResult.error(AppStatus.fromHttp(http(o),AppStatus.BAD_REQUEST),code(o)==null?"OPERACION_NO_COMPLETADA":code(o),message(o));}
}
