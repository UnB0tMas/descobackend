package com.franco.desco.adapter.in.web.priceadjustment;

import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.priceadjustment.PriceAdjustmentModels;
import org.springframework.stereotype.Component;

@Component
public class PriceAdjustmentWebMapper {
    public PriceAdjustmentCommands.ListAdjustments list(int p,int t,Long participacionId,Long operativoVentaId){
        return new PriceAdjustmentCommands.ListAdjustments(new PageRequest<>(p,t,new PriceAdjustmentCommands.Filter(participacionId,operativoVentaId),null,null));
    }

    public PriceAdjustmentCommands.Create command(PriceAdjustmentRequests.Create r){
        return new PriceAdjustmentCommands.Create(r.participacionId(),r.operativoVentaId(),r.condicionComercialId(),r.tipoAjuste(),
                r.precioOriginal(),r.precioAplicado(),r.montoAjuste(),r.porcentajeAjuste(),r.motivo());
    }

    public PriceAdjustmentResponses.Summary response(PriceAdjustmentModels.Summary x){
        return new PriceAdjustmentResponses.Summary(x.ajustePrecioSocioId(),x.participacionId(),x.operativoVentaId(),x.condicionComercialId(),
                x.tipoAjuste(),x.precioOriginal(),x.precioAplicado(),x.montoAjuste(),x.porcentajeAjuste(),x.motivo(),x.fechaHora(),x.estadoAjuste(),x.usuario());
    }

    public PriceAdjustmentResponses.Impact response(PriceAdjustmentModels.Impact x){
        return new PriceAdjustmentResponses.Impact(x.ajustePrecioSocioId(),x.participacionId(),x.operativoVentaId(),x.condicionComercialId(),
                x.tipoAjuste(),x.precioOriginal(),x.precioAplicado(),x.montoAjuste(),x.porcentajeAjuste(),x.motivo(),x.usuarioId(),x.fechaHora(),
                x.estadoAjuste(),x.estado(),x.campaniaVentaId(),x.campania(),x.numeroDocumento(),x.socioNombre(),x.liquidacionesRelacionadas());
    }
}
