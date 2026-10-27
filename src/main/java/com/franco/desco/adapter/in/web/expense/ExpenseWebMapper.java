package com.franco.desco.adapter.in.web.expense;

import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.expense.ExpenseModels;
import org.springframework.stereotype.Component;

@Component
public class ExpenseWebMapper {
    public ExpenseCommands.ListExpenses list(int p,int t,Long campania,Long operativo,String estado){
        return new ExpenseCommands.ListExpenses(new PageRequest<>(p,t,new ExpenseCommands.Filter(campania,operativo,estado),null,null));
    }
    public ExpenseCommands.Create command(ExpenseRequests.Create r){
        return new ExpenseCommands.Create(r.campaniaVentaId(),r.operativoVentaId(),r.tipoGastoId(),r.reglaProrrateoId(),r.fecha(),r.concepto(),r.importe(),r.moneda());
    }
    public ExpenseCommands.Update command(Long id,ExpenseRequests.Update r){
        return new ExpenseCommands.Update(id,r.tipoGastoId(),r.reglaProrrateoId(),r.fecha(),r.concepto(),r.importe(),r.moneda());
    }
    public ExpenseCommands.Prorate command(Long id,ExpenseRequests.Prorate r){
        return new ExpenseCommands.Prorate(id,r.prorrateo()==null?java.util.List.of():r.prorrateo().stream().map(x->new ExpenseCommands.ManualShare(x.participacionId(),x.importeAsignado())).toList());
    }
    public ExpenseResponses.Summary response(ExpenseModels.Summary x){
        return new ExpenseResponses.Summary(x.gastoCampaniaId(),x.campaniaVentaId(),x.campania(),x.operativoVentaId(),x.operativo(),x.tipoGastoId(),x.tipoGasto(),
                x.reglaProrrateoId(),x.reglaProrrateo(),x.fecha(),x.concepto(),x.importe(),x.moneda(),x.estadoProceso(),x.totalProrrateado());
    }
    public ExpenseResponses.Detail response(ExpenseModels.Detail x){
        return new ExpenseResponses.Detail(x.gastoCampaniaId(),x.campaniaVentaId(),x.operativoVentaId(),x.tipoGastoId(),x.tipoGasto(),x.reglaProrrateoId(),
                x.reglaProrrateo(),x.fecha(),x.concepto(),x.importe(),x.moneda(),x.estadoProceso(),x.estado(),x.prorrateo().stream().map(p->new ExpenseResponses.Proration(
                        p.gastoProrrateoSocioId(),p.participacionId(),p.importeAsignado(),p.numeroDocumento(),p.socioNombre())).toList());
    }
}
