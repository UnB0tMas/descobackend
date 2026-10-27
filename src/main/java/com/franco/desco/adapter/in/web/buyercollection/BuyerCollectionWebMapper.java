package com.franco.desco.adapter.in.web.buyercollection;

import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.buyercollection.BuyerCollectionModels;
import org.springframework.stereotype.Component;

@Component
public class BuyerCollectionWebMapper {
    public ListCollections list(int p,int s,Long campaign,Long operation,String status){return new ListCollections(new PageRequest<>(p,s,new Filter(campaign,operation,status),null,null));}
    public GetBalance balance(Long campaign,Long operation){return new GetBalance(campaign,operation);}
    public CreateCollection command(BuyerCollectionRequests.Create r){return new CreateCollection(r.campaniaVentaId(),r.operativoVentaId(),r.importe(),r.moneda(),r.medioPago(),r.numeroOperacion());}
    public ConfirmCollection confirm(Long id){return new ConfirmCollection(id);}
    public CancelCollection cancel(Long id,BuyerCollectionRequests.Cancel r){return new CancelCollection(id,r.motivo());}
    public BuyerCollectionResponses.Summary response(BuyerCollectionModels.Summary x){return new BuyerCollectionResponses.Summary(x.cobroCompradorId(),x.campaniaVentaId(),x.campania(),x.operativoVentaId(),x.operativo(),x.fechaHora(),x.importe(),x.moneda(),x.medioPago(),x.numeroOperacion(),x.estadoProceso());}
    public BuyerCollectionResponses.Balance response(BuyerCollectionModels.Balance x){return new BuyerCollectionResponses.Balance(x.campaniaVentaId(),x.operativoVentaId(),x.totalValorizado(),x.totalCobrado(),x.saldoPendiente());}
    public BuyerCollectionResponses.Created created(Long id){return new BuyerCollectionResponses.Created(id);}
}
