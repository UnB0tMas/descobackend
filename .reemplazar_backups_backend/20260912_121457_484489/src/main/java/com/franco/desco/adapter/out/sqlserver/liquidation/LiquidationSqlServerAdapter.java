package com.franco.desco.adapter.out.sqlserver.liquidation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.liquidation.port.out.LiquidationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.liquidation.LiquidationModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
public class LiquidationSqlServerAdapter implements LiquidationPersistencePort {
    private final SqlServerPaExecutor executor; private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list,get,calculate,recalculate,approve,cancel;

    public LiquidationSqlServerAdapter(SqlServerPaFactory f,SqlServerPaExecutor e,PaPayloadFactory p){
        executor=e;payloadFactory=p;
        list=f.callWithResultSets("finanzas","PA_LiquidacionSocio_Sel_Listado","items");
        get=f.callWithResultSets("finanzas","PA_LiquidacionSocio_Sel_Detalle","header","details","payments");
        calculate=f.call("finanzas","PA_LiquidacionSocio_Ins_Calcular");
        recalculate=f.call("finanzas","PA_LiquidacionSocio_Ins_RecalcularVersion");
        approve=f.call("finanzas","PA_LiquidacionSocio_Upd_Aprobar");
        cancel=f.call("finanzas","PA_LiquidacionSocio_Upd_Anular");
    }

    public PersistenceResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations c,SessionIdentity i,RequestMetadata m){
        var pg=c.page();var f=pg.filtros();
        var out=executor.executeJson(list,payloadFactory.forQuery(i,m,Map.of("filtros",map(
                "campaniaVentaId",f==null?null:f.campaniaVentaId(),"participacionId",f==null?null:f.participacionId(),
                "estadoProceso",f==null?null:f.estadoProceso(),"pagina",pg.pagina(),"tamanoPagina",pg.tamanio()
        ))));
        return PaAdapterSupport.page(out,rows(out,"items"),pg.pagina(),pg.tamanio(),this::summary,"No se pudieron consultar las liquidaciones.");
    }

    public PersistenceResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(get,payloadFactory.forQuery(i,m,Map.of("liquidacion",Map.of("liquidacionSocioId",c.liquidacionSocioId()))));
        if(!PaAdapterSupport.success(out))return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo consultar la liquidación."));
        var h=one(out,"header");if(h==null)return PersistenceResult.error("La liquidación seleccionada no está disponible.");
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Liquidación consultada correctamente."),detail(h,rows(out,"details"),rows(out,"payments")));
    }

    public PersistenceResult<Long> calculate(LiquidationCommands.Calculate c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(calculate,payloadFactory.forWrite(i,m,c,Map.of("liquidacion",Map.of("participacionId",c.participacionId()))));
        return PaAdapterSupport.result(out,SqlValues.longValue(out,"nLiquidacionSocioId"),"No se pudo calcular la liquidación.");
    }

    public PersistenceResult<Long> recalculate(LiquidationCommands.Recalculate c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(recalculate,payloadFactory.forWrite(i,m,c,Map.of("liquidacion",map("liquidacionSocioId",c.liquidacionSocioId(),"motivo",c.motivo()))));
        return PaAdapterSupport.result(out,SqlValues.longValue(out,"nNuevaLiquidacionSocioId"),"No se pudo recalcular la liquidación.");
    }

    public PersistenceResult<Void> approve(LiquidationCommands.Approve c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(approve,payloadFactory.forWrite(i,m,c,Map.of("liquidacion",Map.of("liquidacionSocioId",c.liquidacionSocioId()))));
        return PaAdapterSupport.result(out,null,"No se pudo aprobar la liquidación.");
    }

    public PersistenceResult<Void> cancel(LiquidationCommands.Cancel c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(cancel,payloadFactory.forWrite(i,m,c,Map.of("liquidacion",map("liquidacionSocioId",c.liquidacionSocioId(),"motivo",c.motivo()))));
        return PaAdapterSupport.result(out,null,"No se pudo anular la liquidación.");
    }

    private LiquidationModels.Summary summary(Map<String,Object>r){
        return new LiquidationModels.Summary(
                SqlValues.longValue(r,"liquidacionSocioId"),SqlValues.longValue(r,"participacionId"),SqlValues.longValue(r,"campaniaVentaId"),
                SqlValues.string(r,"campania"),SqlValues.intValue(r,"version"),SqlValues.instant(r,"fechaCalculo"),SqlValues.decimal(r,"importeBruto"),
                SqlValues.decimal(r,"totalAjustes"),SqlValues.decimal(r,"totalGastos"),SqlValues.decimal(r,"totalBonificaciones"),SqlValues.decimal(r,"importeNeto"),
                SqlValues.string(r,"moneda"),SqlValues.string(r,"estadoProceso"),SqlValues.decimal(r,"totalPagado"),SqlValues.decimal(r,"saldoPendiente")
        );
    }

    private LiquidationModels.Detail detail(Map<String,Object>h,List<Map<String,Object>>d,List<Map<String,Object>>p){
        return new LiquidationModels.Detail(
                SqlValues.longValue(h,"liquidacion_socio_id"),SqlValues.longValue(h,"participacion_campania_socio_id"),SqlValues.intValue(h,"version"),
                SqlValues.instant(h,"fecha_calculo"),SqlValues.decimal(h,"importe_bruto"),SqlValues.decimal(h,"total_ajustes"),SqlValues.decimal(h,"total_gastos"),
                SqlValues.decimal(h,"total_bonificaciones"),SqlValues.decimal(h,"importe_neto"),SqlValues.string(h,"moneda"),SqlValues.string(h,"estado_proceso"),
                SqlValues.bool(h,"estado"),SqlValues.longValue(h,"campaniaVentaId"),SqlValues.string(h,"numeroDocumento"),SqlValues.string(h,"socioNombre"),
                SqlValues.decimal(h,"totalPagado"),SqlValues.decimal(h,"saldoPendiente"),d.stream().map(this::line).toList(),p.stream().map(this::payment).toList()
        );
    }

    private LiquidationModels.Line line(Map<String,Object>r){
        return new LiquidationModels.Line(SqlValues.longValue(r,"liquidacionDetalleId"),SqlValues.string(r,"tipo"),SqlValues.longValue(r,"entregaDetalleId"),
                SqlValues.longValue(r,"gastoProrrateoSocioId"),SqlValues.longValue(r,"ajustePrecioSocioId"),SqlValues.string(r,"concepto"),SqlValues.decimal(r,"importe"));
    }
    private LiquidationModels.Payment payment(Map<String,Object>r){
        return new LiquidationModels.Payment(SqlValues.longValue(r,"pagoSocioId"),SqlValues.instant(r,"fechaHora"),SqlValues.decimal(r,"importe"),
                SqlValues.string(r,"medioPago"),SqlValues.string(r,"numeroOperacion"),SqlValues.string(r,"estadoProceso"));
    }

    private List<Map<String,Object>>rows(Map<String,Object>o,String k){return new PaResultSets(o).rows(k);}
    private Map<String,Object>one(Map<String,Object>o,String k){return new PaResultSets(o).one(k).orElse(null);}
    private static Map<String,Object>map(Object...v){Map<String,Object>m=new LinkedHashMap<>();for(int n=0;n<v.length;n+=2)if(v[n+1]!=null)m.put((String)v[n],v[n+1]);return m;}
}
