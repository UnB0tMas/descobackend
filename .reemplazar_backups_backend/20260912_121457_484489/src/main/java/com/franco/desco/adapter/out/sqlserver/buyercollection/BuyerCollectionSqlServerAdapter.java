package com.franco.desco.adapter.out.sqlserver.buyercollection;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.buyercollection.BuyerCollectionCommands;
import com.franco.desco.application.buyercollection.port.out.BuyerCollectionPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.buyercollection.BuyerCollectionModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
public class BuyerCollectionSqlServerAdapter implements BuyerCollectionPersistencePort {
    private final SqlServerPaExecutor executor; private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list,balance,create,confirm,cancel;

    public BuyerCollectionSqlServerAdapter(SqlServerPaFactory factory,SqlServerPaExecutor executor,PaPayloadFactory payloadFactory){
        this.executor=executor;this.payloadFactory=payloadFactory;
        list=factory.callWithResultSets("finanzas","PA_CobroComprador_Sel_Listado","items");
        balance=factory.callWithResultSets("finanzas","PA_CobroComprador_Sel_SaldoCampania","balance");
        create=factory.call("finanzas","PA_CobroComprador_Ins_Registro");
        confirm=factory.call("finanzas","PA_CobroComprador_Upd_Confirmar");
        cancel=factory.call("finanzas","PA_CobroComprador_Upd_Anular");
    }

    public PersistenceResult<PageResult<BuyerCollectionModels.Summary>> list(BuyerCollectionCommands.ListCollections c,SessionIdentity i,RequestMetadata m){
        var pg=c.page();var f=pg.filtros();
        var out=executor.executeJson(list,payloadFactory.forQuery(i,m,Map.of("filtros",map(
                "campaniaVentaId",f==null?null:f.campaniaVentaId(),"operativoVentaId",f==null?null:f.operativoVentaId(),
                "estadoProceso",f==null?null:f.estadoProceso(),"pagina",pg.pagina(),"tamanoPagina",pg.tamanio()
        ))));
        return PaAdapterSupport.page(out,rows(out,"items"),pg.pagina(),pg.tamanio(),this::summary,"No se pudieron consultar los cobros.");
    }

    public PersistenceResult<BuyerCollectionModels.Balance> balance(BuyerCollectionCommands.GetBalance c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(balance,payloadFactory.forQuery(i,m,Map.of("filtros",map("campaniaVentaId",c.campaniaVentaId(),"operativoVentaId",c.operativoVentaId()))));
        if(!PaAdapterSupport.success(out)) return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo consultar el saldo del comprador."));
        var r=one(out,"balance");if(r==null)return PersistenceResult.error("No se encontró saldo para la selección indicada.");
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Saldo consultado correctamente."),new BuyerCollectionModels.Balance(
                SqlValues.longValue(r,"campaniaVentaId"),SqlValues.longValue(r,"operativoVentaId"),SqlValues.decimal(r,"totalValorizado"),
                SqlValues.decimal(r,"totalCobrado"),SqlValues.decimal(r,"saldoPendiente")
        ));
    }

    public PersistenceResult<Long> create(BuyerCollectionCommands.CreateCollection c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(create,payloadFactory.forWrite(i,m,c,Map.of("cobro",map(
                "campaniaVentaId",c.campaniaVentaId(),"operativoVentaId",c.operativoVentaId(),"importe",c.importe(),
                "moneda",c.moneda(),"medioPago",c.medioPago(),"numeroOperacion",c.numeroOperacion()
        ))));
        return PaAdapterSupport.result(out,SqlValues.longValue(out,"nCobroCompradorId"),"No se pudo registrar el cobro.");
    }
    public PersistenceResult<Void> confirm(BuyerCollectionCommands.ConfirmCollection c,SessionIdentity i,RequestMetadata m){
        return PaAdapterSupport.result(executor.executeJson(confirm,payloadFactory.forWrite(i,m,c,Map.of("cobro",Map.of("cobroCompradorId",c.cobroCompradorId())))),null,"No se pudo confirmar el cobro.");
    }
    public PersistenceResult<Void> cancel(BuyerCollectionCommands.CancelCollection c,SessionIdentity i,RequestMetadata m){
        return PaAdapterSupport.result(executor.executeJson(cancel,payloadFactory.forWrite(i,m,c,Map.of("cobro",map("cobroCompradorId",c.cobroCompradorId(),"motivo",c.motivo())))),null,"No se pudo anular el cobro.");
    }

    private BuyerCollectionModels.Summary summary(Map<String,Object>r){
        return new BuyerCollectionModels.Summary(SqlValues.longValue(r,"cobroCompradorId"),SqlValues.longValue(r,"campaniaVentaId"),SqlValues.string(r,"campania"),
                SqlValues.longValue(r,"operativoVentaId"),SqlValues.string(r,"operativo"),SqlValues.instant(r,"fechaHora"),SqlValues.decimal(r,"importe"),
                SqlValues.string(r,"moneda"),SqlValues.string(r,"medioPago"),SqlValues.string(r,"numeroOperacion"),SqlValues.string(r,"estadoProceso"));
    }
    private List<Map<String,Object>>rows(Map<String,Object>o,String k){return new PaResultSets(o).rows(k);}
    private Map<String,Object>one(Map<String,Object>o,String k){return new PaResultSets(o).one(k).orElse(null);}
    private static Map<String,Object>map(Object...v){Map<String,Object>m=new LinkedHashMap<>();for(int n=0;n<v.length;n+=2)if(v[n+1]!=null)m.put((String)v[n],v[n+1]);return m;}
}
