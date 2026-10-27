package com.franco.desco.adapter.in.web.liquidation;

import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.liquidation.LiquidationModels;
import org.springframework.stereotype.Component;

@Component
public class LiquidationWebMapper {
    public LiquidationCommands.ListLiquidations list(int p,int t,Long campania,Long participacion,String estado){
        return new LiquidationCommands.ListLiquidations(new PageRequest<>(p,t,new LiquidationCommands.Filter(campania,participacion,estado),null,null));
    }
    public LiquidationResponses.Summary response(LiquidationModels.Summary x){
        return new LiquidationResponses.Summary(x.liquidacionSocioId(),x.participacionId(),x.campaniaVentaId(),x.campania(),x.version(),x.fechaCalculo(),
                x.importeBruto(),x.totalAjustes(),x.totalGastos(),x.totalBonificaciones(),x.importeNeto(),x.moneda(),x.estadoProceso(),x.totalPagado(),x.saldoPendiente());
    }
    public LiquidationResponses.Detail response(LiquidationModels.Detail x){
        return new LiquidationResponses.Detail(x.liquidacionSocioId(),x.participacionId(),x.version(),x.fechaCalculo(),x.importeBruto(),x.totalAjustes(),
                x.totalGastos(),x.totalBonificaciones(),x.importeNeto(),x.moneda(),x.estadoProceso(),x.estado(),x.campaniaVentaId(),x.numeroDocumento(),x.socioNombre(),
                x.totalPagado(),x.saldoPendiente(),x.detalle().stream().map(d->new LiquidationResponses.Line(d.liquidacionDetalleId(),d.tipo(),d.entregaDetalleId(),
                        d.gastoProrrateoSocioId(),d.ajustePrecioSocioId(),d.concepto(),d.importe())).toList(),
                x.pagos().stream().map(p->new LiquidationResponses.Payment(p.pagoSocioId(),p.fechaHora(),p.importe(),p.medioPago(),p.numeroOperacion(),p.estadoProceso())).toList());
    }
}
