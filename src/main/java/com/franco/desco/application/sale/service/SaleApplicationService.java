package com.franco.desco.application.sale.service;

import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.sale.port.in.SaleUseCase;
import com.franco.desco.application.sale.port.out.SalePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.sale.SaleModels;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SaleApplicationService implements SaleUseCase {
    private final SalePersistencePort persistence;
    public SaleApplicationService(SalePersistencePort persistence){this.persistence=persistence;}
    @Override public AppResult<List<SaleModels.Summary>> list(SessionIdentity i,Long u,String s){return ok(persistence.list(i,u,s),"VENTAS_LISTADAS","VENTAS_NO_LISTADAS",AppStatus.BAD_REQUEST);}
    @Override public AppResult<SaleModels.Detail> get(SessionIdentity i,Long id){return ok(persistence.get(i,id),"VENTA_OBTENIDA","VENTA_NO_DISPONIBLE",AppStatus.NOT_FOUND);}
    @Override public AppResult<List<SaleModels.PaymentMethod>> paymentMethods(SessionIdentity i){return ok(persistence.paymentMethods(i),"METODOS_PAGO_LISTADOS","METODOS_PAGO_NO_LISTADOS",AppStatus.BAD_REQUEST);}
    @Override public AppResult<Long> create(SessionIdentity i,SaleCommands.Create c){return ApplicationResults.created(persistence.create(i,c),"VENTA_CREADA","VENTA_NO_CREADA");}
    @Override public AppResult<Long> pay(SessionIdentity i,SaleCommands.Pay c){return ApplicationResults.created(persistence.pay(i,c),"PAGO_REGISTRADO","PAGO_NO_REGISTRADO");}
    @Override public AppResult<Void> deliver(SessionIdentity i,SaleCommands.Deliver c){return ok(persistence.deliver(i,c),"VENTA_ENTREGADA","VENTA_NO_ENTREGADA",AppStatus.BAD_REQUEST);}
    @Override public AppResult<Void> cancel(SessionIdentity i,SaleCommands.Cancel c){return ok(persistence.cancel(i,c),"VENTA_ANULADA","VENTA_NO_ANULADA",AppStatus.BAD_REQUEST);}
    @Override public AppResult<Void> cancelPayment(SessionIdentity i,SaleCommands.CancelPayment c){return ok(persistence.cancelPayment(i,c),"PAGO_ANULADO","PAGO_NO_ANULADO",AppStatus.BAD_REQUEST);}
    @Override public AppResult<Long> issueReceipt(SessionIdentity i,SaleCommands.IssueReceipt c){return ApplicationResults.created(persistence.issueReceipt(i,c),"COMPROBANTE_EMITIDO","COMPROBANTE_NO_EMITIDO");}
    private <T> AppResult<T> ok(PersistenceResult<T> r,String ok,String err,AppStatus status){return ApplicationResults.ok(r,ok,err,status);}
}
