package com.franco.desco.adapter.out.sqlserver.expense;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.expense.port.out.ExpensePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.expense.ExpenseModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
public class ExpenseSqlServerAdapter implements ExpensePersistencePort {
    private final SqlServerPaExecutor executor; private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list,get,create,update,prorate,approve,cancel;

    public ExpenseSqlServerAdapter(SqlServerPaFactory f,SqlServerPaExecutor e,PaPayloadFactory p){
        executor=e;payloadFactory=p;
        list=f.callWithResultSets("finanzas","PA_GastoCampania_Sel_Listado","items");
        get=f.callWithResultSets("finanzas","PA_GastoCampania_Sel_Detalle","header","shares");
        create=f.call("finanzas","PA_GastoCampania_Ins_Registro");
        update=f.call("finanzas","PA_GastoCampania_Upd_Registro");
        prorate=f.call("finanzas","PA_GastoCampania_Ins_EjecutarProrrateo");
        approve=f.call("finanzas","PA_GastoCampania_Upd_Aprobar");
        cancel=f.call("finanzas","PA_GastoCampania_Upd_Anular");
    }

    public PersistenceResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses c,SessionIdentity i,RequestMetadata m){
        var pg=c.page();var f=pg.filtros();
        var out=executor.executeJson(list,payloadFactory.forQuery(i,m,Map.of("filtros",map(
                "campaniaVentaId",f==null?null:f.campaniaVentaId(),
                "operativoVentaId",f==null?null:f.operativoVentaId(),
                "estadoProceso",f==null?null:f.estadoProceso(),
                "pagina",pg.pagina(),"tamanoPagina",pg.tamanio()
        ))));
        return PaAdapterSupport.page(out,rows(out,"items"),pg.pagina(),pg.tamanio(),this::summary,"No se pudieron consultar los gastos.");
    }

    public PersistenceResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(get,payloadFactory.forQuery(i,m,Map.of("gasto",Map.of("gastoCampaniaId",c.gastoCampaniaId()))));
        if(!PaAdapterSupport.success(out))return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo consultar el gasto."));
        var h=one(out,"header");if(h==null)return PersistenceResult.error("El gasto seleccionado no está disponible.");
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Gasto consultado correctamente."),detail(h,rows(out,"shares")));
    }

    public PersistenceResult<Long> create(ExpenseCommands.Create c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(create,payloadFactory.forWrite(i,m,c,Map.of("gasto",map(
                "campaniaVentaId",c.campaniaVentaId(),"operativoVentaId",c.operativoVentaId(),"tipoGastoId",c.tipoGastoId(),
                "reglaProrrateoId",c.reglaProrrateoId(),"fecha",c.fecha(),"concepto",c.concepto(),"importe",c.importe(),"moneda",c.moneda()
        ))));
        return PaAdapterSupport.result(out,SqlValues.longValue(out,"nGastoCampaniaId"),"No se pudo registrar el gasto.");
    }

    public PersistenceResult<Void> update(ExpenseCommands.Update c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(update,payloadFactory.forWrite(i,m,c,Map.of("gasto",map(
                "gastoCampaniaId",c.gastoCampaniaId(),"tipoGastoId",c.tipoGastoId(),"reglaProrrateoId",c.reglaProrrateoId(),
                "fecha",c.fecha(),"concepto",c.concepto(),"importe",c.importe(),"moneda",c.moneda()
        ))));
        return PaAdapterSupport.result(out,null,"No se pudo actualizar el gasto.");
    }

    public PersistenceResult<Void> prorate(ExpenseCommands.Prorate c,SessionIdentity i,RequestMetadata m){
        var body=new LinkedHashMap<String,Object>();
        body.put("gasto",Map.of("gastoCampaniaId",c.gastoCampaniaId()));
        if(c.prorrateo()!=null&&!c.prorrateo().isEmpty())body.put("prorrateo",c.prorrateo().stream().map(x->map("participacionId",x.participacionId(),"importeAsignado",x.importeAsignado())).toList());
        var out=executor.executeJson(prorate,payloadFactory.forWrite(i,m,c,body));
        return PaAdapterSupport.result(out,null,"No se pudo calcular el prorrateo.");
    }

    public PersistenceResult<Void> approve(ExpenseCommands.Approve c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(approve,payloadFactory.forWrite(i,m,c,Map.of("gasto",Map.of("gastoCampaniaId",c.gastoCampaniaId()))));
        return PaAdapterSupport.result(out,null,"No se pudo aprobar el gasto.");
    }

    public PersistenceResult<Void> cancel(ExpenseCommands.Cancel c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(cancel,payloadFactory.forWrite(i,m,c,Map.of("gasto",map("gastoCampaniaId",c.gastoCampaniaId(),"motivo",c.motivo()))));
        return PaAdapterSupport.result(out,null,"No se pudo anular el gasto.");
    }

    private ExpenseModels.Summary summary(Map<String,Object>r){
        return new ExpenseModels.Summary(
                SqlValues.longValue(r,"gastoCampaniaId"),SqlValues.longValue(r,"campaniaVentaId"),SqlValues.string(r,"campania"),
                SqlValues.longValue(r,"operativoVentaId"),SqlValues.string(r,"operativo"),shortValue(r,"tipoGastoId"),SqlValues.string(r,"tipoGasto"),
                shortValue(r,"reglaProrrateoId"),SqlValues.string(r,"reglaProrrateo"),SqlValues.localDate(r,"fecha"),SqlValues.string(r,"concepto"),
                SqlValues.decimal(r,"importe"),SqlValues.string(r,"moneda"),SqlValues.string(r,"estadoProceso"),SqlValues.decimal(r,"totalProrrateado")
        );
    }

    private ExpenseModels.Detail detail(Map<String,Object>h,List<Map<String,Object>>shares){
        return new ExpenseModels.Detail(
                SqlValues.longValue(h,"gasto_campania_id"),SqlValues.longValue(h,"campania_venta_id"),SqlValues.longValue(h,"operativo_venta_id"),
                shortValue(h,"tipo_gasto_id"),SqlValues.string(h,"tipoGasto"),shortValue(h,"regla_prorrateo_id"),SqlValues.string(h,"reglaProrrateo"),
                SqlValues.localDate(h,"fecha"),SqlValues.string(h,"concepto"),SqlValues.decimal(h,"importe"),SqlValues.string(h,"moneda"),
                SqlValues.string(h,"estado_proceso"),SqlValues.bool(h,"estado"),shares.stream().map(this::share).toList()
        );
    }

    private ExpenseModels.Proration share(Map<String,Object>r){
        return new ExpenseModels.Proration(SqlValues.longValue(r,"gastoProrrateoSocioId"),SqlValues.longValue(r,"participacionId"),
                SqlValues.decimal(r,"importeAsignado"),SqlValues.string(r,"numeroDocumento"),SqlValues.string(r,"socioNombre"));
    }

    private Short shortValue(Map<String,Object>r,String k){Integer v=SqlValues.intValue(r,k);return v==null?null:v.shortValue();}
    private List<Map<String,Object>> rows(Map<String,Object>o,String k){return new PaResultSets(o).rows(k);}
    private Map<String,Object> one(Map<String,Object>o,String k){return new PaResultSets(o).one(k).orElse(null);}
    private static Map<String,Object> map(Object...v){Map<String,Object>m=new LinkedHashMap<>();for(int n=0;n<v.length;n+=2)if(v[n+1]!=null)m.put((String)v[n],v[n+1]);return m;}
}
