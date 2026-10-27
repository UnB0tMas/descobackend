package com.franco.desco.adapter.out.sqlserver.priceadjustment;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.priceadjustment.port.out.PriceAdjustmentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.priceadjustment.PriceAdjustmentModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class PriceAdjustmentSqlServerAdapter implements PriceAdjustmentPersistencePort {
    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list;
    private final SimpleJdbcCall impact;
    private final SimpleJdbcCall create;
    private final SimpleJdbcCall cancel;

    public PriceAdjustmentSqlServerAdapter(SqlServerPaFactory factory, SqlServerPaExecutor executor, PaPayloadFactory payloadFactory) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;
        this.list = factory.callWithResultSets("comercial", "PA_AjustePrecioSocio_Sel_Listado", "items");
        this.impact = factory.callWithResultSets("comercial", "PA_AjustePrecioSocio_Sel_Impacto", "impact");
        this.create = factory.call("comercial", "PA_AjustePrecioSocio_Ins_Registro");
        this.cancel = factory.call("comercial", "PA_AjustePrecioSocio_Upd_Anular");
    }

    public PersistenceResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments c, SessionIdentity i, RequestMetadata m) {
        var page = c.page();
        var f = page.filtros();
        var payload = payloadFactory.forQuery(i, m, Map.of("filtros", map(
                "participacionId", f == null ? null : f.participacionId(),
                "operativoVentaId", f == null ? null : f.operativoVentaId(),
                "pagina", page.pagina(),
                "tamanoPagina", page.tamanio()
        )));
        var out = executor.executeJson(list, payload);
        return PaAdapterSupport.page(out, rows(out, "items"), page.pagina(), page.tamanio(), this::summary, "No se pudieron consultar los ajustes.");
    }

    public PersistenceResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(impact, payloadFactory.forQuery(i, m, Map.of("ajuste", Map.of("ajustePrecioSocioId", c.ajustePrecioSocioId()))));
        if (!PaAdapterSupport.success(out)) return PersistenceResult.error(PaAdapterSupport.message(out, "No se pudo consultar el ajuste."));
        var row = new PaResultSets(out).one("impact").orElse(null);
        return row == null
                ? PersistenceResult.error("El ajuste seleccionado no está disponible.")
                : PersistenceResult.ok(PaAdapterSupport.message(out, "Impacto consultado correctamente."), impact(row));
    }

    public PersistenceResult<Long> create(PriceAdjustmentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(create, payloadFactory.forWrite(i, m, c, Map.of("ajuste", map(
                "participacionId", c.participacionId(),
                "operativoVentaId", c.operativoVentaId(),
                "condicionComercialId", c.condicionComercialId(),
                "tipoAjuste", c.tipoAjuste(),
                "precioOriginal", c.precioOriginal(),
                "precioAplicado", c.precioAplicado(),
                "montoAjuste", c.montoAjuste(),
                "porcentajeAjuste", c.porcentajeAjuste(),
                "motivo", c.motivo()
        ))));
        return PaAdapterSupport.result(out, SqlValues.longValue(out, "nAjustePrecioSocioId"), "No se pudo registrar el ajuste.");
    }

    public PersistenceResult<Void> cancel(PriceAdjustmentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(cancel, payloadFactory.forWrite(i, m, c, Map.of("ajuste", map(
                "ajustePrecioSocioId", c.ajustePrecioSocioId(),
                "motivo", c.motivo()
        ))));
        return PaAdapterSupport.result(out, null, "No se pudo anular el ajuste.");
    }

    private PriceAdjustmentModels.Summary summary(Map<String,Object> r) {
        return new PriceAdjustmentModels.Summary(
                SqlValues.longValue(r,"ajustePrecioSocioId"),
                SqlValues.longValue(r,"participacionId"),
                SqlValues.longValue(r,"operativoVentaId"),
                SqlValues.longValue(r,"condicionComercialId"),
                SqlValues.string(r,"tipoAjuste"),
                SqlValues.decimal(r,"precioOriginal"),
                SqlValues.decimal(r,"precioAplicado"),
                SqlValues.decimal(r,"montoAjuste"),
                SqlValues.decimal(r,"porcentajeAjuste"),
                SqlValues.string(r,"motivo"),
                SqlValues.instant(r,"fechaHora"),
                SqlValues.string(r,"estadoAjuste"),
                SqlValues.string(r,"usuario")
        );
    }

    private PriceAdjustmentModels.Impact impact(Map<String,Object> r) {
        return new PriceAdjustmentModels.Impact(
                SqlValues.longValue(r,"ajuste_precio_socio_id"),
                SqlValues.longValue(r,"participacion_campania_socio_id"),
                SqlValues.longValue(r,"operativo_venta_id"),
                SqlValues.longValue(r,"condicion_comercial_id"),
                SqlValues.string(r,"tipo_ajuste"),
                SqlValues.decimal(r,"precio_original"),
                SqlValues.decimal(r,"precio_aplicado"),
                SqlValues.decimal(r,"monto_ajuste"),
                SqlValues.decimal(r,"porcentaje_ajuste"),
                SqlValues.string(r,"motivo"),
                SqlValues.longValue(r,"usuario_id"),
                SqlValues.instant(r,"fecha_hora"),
                SqlValues.string(r,"estado_ajuste"),
                SqlValues.bool(r,"estado"),
                SqlValues.longValue(r,"campaniaVentaId"),
                SqlValues.string(r,"campania"),
                SqlValues.string(r,"numeroDocumento"),
                SqlValues.string(r,"socioNombre"),
                SqlValues.longValue(r,"liquidacionesRelacionadas")
        );
    }

    private List<Map<String,Object>> rows(Map<String,Object> out,String key){return new PaResultSets(out).rows(key);}
    private static Map<String,Object> map(Object...v){Map<String,Object>m=new LinkedHashMap<>();for(int n=0;n<v.length;n+=2)if(v[n+1]!=null)m.put((String)v[n],v[n+1]);return m;}
}
