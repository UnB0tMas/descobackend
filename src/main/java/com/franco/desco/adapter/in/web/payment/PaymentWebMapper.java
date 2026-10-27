package com.franco.desco.adapter.in.web.payment;

import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.payment.PaymentModels;
import org.springframework.stereotype.Component;

@Component
public class PaymentWebMapper {
    public ListPayments list(int page,int size,Long liquidationId,String status){
        return new ListPayments(new PageRequest<>(page,size,new Filter(liquidationId,status),null,null));
    }
    public GetPayment get(Long id){ return new GetPayment(id); }
    public CreatePayment command(PaymentRequests.Create r){ return new CreatePayment(r.liquidacionSocioId(),r.importe(),r.medioPago(),r.numeroOperacion()); }
    public ConfirmPayment confirm(Long id){ return new ConfirmPayment(id); }
    public CancelPayment cancel(Long id,PaymentRequests.Cancel r){ return new CancelPayment(id,r.motivo()); }

    public PaymentResponses.Summary response(PaymentModels.Summary x){
        return new PaymentResponses.Summary(x.pagoSocioId(),x.liquidacionSocioId(),x.fechaHora(),x.importe(),x.medioPago(),x.numeroOperacion(),x.estadoProceso(),x.importeNeto(),x.numeroDocumento(),x.socioNombre(),x.saldoPosteriorPago());
    }
    public PaymentResponses.Detail response(PaymentModels.Detail x){
        return new PaymentResponses.Detail(x.pagoSocioId(),x.liquidacionSocioId(),x.fechaHora(),x.importe(),x.medioPago(),x.numeroOperacion(),x.estadoProceso(),x.estado(),x.importeNeto(),x.totalConfirmadoHastaPago(),x.saldoPosteriorPago(),x.totalPagadoActual(),x.saldoPendienteActual(),x.saldoPendiente());
    }
    public PaymentResponses.Created created(Long id){ return new PaymentResponses.Created(id); }
}
