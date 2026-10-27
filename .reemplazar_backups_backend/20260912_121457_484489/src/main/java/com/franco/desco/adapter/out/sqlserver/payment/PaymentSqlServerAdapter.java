package com.franco.desco.adapter.out.sqlserver.payment;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.payment.PaymentCommands;
import com.franco.desco.application.payment.port.out.PaymentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.payment.PaymentModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
public class PaymentSqlServerAdapter implements PaymentPersistencePort {
    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list, get, create, confirm, cancel;

    public PaymentSqlServerAdapter(SqlServerPaFactory factory, SqlServerPaExecutor executor, PaPayloadFactory payloadFactory) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;
        list = factory.callWithResultSets("finanzas","PA_PagoSocio_Sel_Listado","items");
        get = factory.callWithResultSets("finanzas","PA_PagoSocio_Sel_Detalle","header");
        create = factory.call("finanzas","PA_PagoSocio_Ins_Registro");
        confirm = factory.call("finanzas","PA_PagoSocio_Upd_Confirmar");
        cancel = factory.call("finanzas","PA_PagoSocio_Upd_Anular");
    }

    @Override
    public PersistenceResult<PageResult<PaymentModels.Summary>> list(PaymentCommands.ListPayments c, SessionIdentity i, RequestMetadata m) {
        var pg = c.page();
        var f = pg.filtros();
        var body = new LinkedHashMap<String,Object>();
        body.put("filtros", map("liquidacionSocioId", f == null ? null : f.liquidacionSocioId(), "estadoProceso", f == null ? null : f.estadoProceso()));
        body.put("paginacion", Map.of("pagina", pg.pagina(), "tamano", pg.tamanio()));
        var out = executor.executeJson(list, payloadFactory.forQuery(i,m,body));
        return PaAdapterSupport.page(out, rows(out,"items"), pg.pagina(), pg.tamanio(), this::summary, "No se pudieron consultar los pagos.");
    }

    @Override
    public PersistenceResult<PaymentModels.Detail> get(PaymentCommands.GetPayment c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(get, payloadFactory.forQuery(i,m,Map.of("pago",Map.of("pagoSocioId",c.pagoSocioId()))));
        if (!PaAdapterSupport.success(out)) return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo consultar el pago."));
        var row = one(out,"header");
        if (row == null) return PersistenceResult.error("El pago seleccionado no está disponible.");
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Pago consultado correctamente."), detail(row));
    }

    @Override
    public PersistenceResult<Long> create(PaymentCommands.CreatePayment c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(create, payloadFactory.forWrite(i,m,c,Map.of("pago",map(
                "liquidacionSocioId",c.liquidacionSocioId(),"importe",c.importe(),"medioPago",c.medioPago(),"numeroOperacion",c.numeroOperacion()
        ))));
        return PaAdapterSupport.result(out,SqlValues.longValue(out,"nPagoSocioId"),"No se pudo registrar el pago.");
    }

    @Override
    public PersistenceResult<Void> confirm(PaymentCommands.ConfirmPayment c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(confirm,payloadFactory.forWrite(i,m,c,Map.of("pago",Map.of("pagoSocioId",c.pagoSocioId()))));
        return PaAdapterSupport.result(out,null,"No se pudo confirmar el pago.");
    }

    @Override
    public PersistenceResult<Void> cancel(PaymentCommands.CancelPayment c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(cancel,payloadFactory.forWrite(i,m,c,Map.of("pago",map("pagoSocioId",c.pagoSocioId(),"motivo",c.motivo()))));
        return PaAdapterSupport.result(out,null,"No se pudo anular el pago.");
    }

    private PaymentModels.Summary summary(Map<String,Object> r) {
        return new PaymentModels.Summary(
                SqlValues.longValue(r,"pagoSocioId"),SqlValues.longValue(r,"liquidacionSocioId"),SqlValues.instant(r,"fechaHora"),
                SqlValues.decimal(r,"importe"),SqlValues.string(r,"medioPago"),SqlValues.string(r,"numeroOperacion"),
                SqlValues.string(r,"estadoProceso"),SqlValues.decimal(r,"importeNeto"),SqlValues.string(r,"numeroDocumento"),
                SqlValues.string(r,"socioNombre"),SqlValues.decimal(r,"saldoPosteriorPago")
        );
    }

    private PaymentModels.Detail detail(Map<String,Object> r) {
        return new PaymentModels.Detail(
                SqlValues.longValue(r,"pagoSocioId"),SqlValues.longValue(r,"liquidacionSocioId"),SqlValues.instant(r,"fechaHora"),
                SqlValues.decimal(r,"importe"),SqlValues.string(r,"medioPago"),SqlValues.string(r,"numeroOperacion"),
                SqlValues.string(r,"estadoProceso"),SqlValues.bool(r,"estado"),SqlValues.decimal(r,"importeNeto"),
                SqlValues.decimal(r,"totalConfirmadoHastaPago"),SqlValues.decimal(r,"saldoPosteriorPago"),
                SqlValues.decimal(r,"totalPagadoActual"),SqlValues.decimal(r,"saldoPendienteActual"),SqlValues.decimal(r,"saldoPendiente")
        );
    }

    private List<Map<String,Object>> rows(Map<String,Object> o,String key){ return new PaResultSets(o).rows(key); }
    private Map<String,Object> one(Map<String,Object> o,String key){ return new PaResultSets(o).one(key).orElse(null); }
    private static Map<String,Object> map(Object... values){
        Map<String,Object> result=new LinkedHashMap<>();
        for(int x=0;x<values.length;x+=2) if(values[x+1]!=null) result.put((String)values[x],values[x+1]);
        return result;
    }
}
