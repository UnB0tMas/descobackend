package com.franco.desco.adapter.out.sqlserver.incident;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.incident.port.out.IncidentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.incident.IncidentModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class IncidentSqlServerAdapter implements IncidentPersistencePort {
    private final SqlServerPaExecutor executor;
    private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list;
    private final SimpleJdbcCall get;
    private final SimpleJdbcCall create;
    private final SimpleJdbcCall review;
    private final SimpleJdbcCall resolve;
    private final SimpleJdbcCall cancel;

    public IncidentSqlServerAdapter(SqlServerPaFactory factory, SqlServerPaExecutor executor, PaPayloadFactory payloadFactory) {
        this.executor = executor;
        this.payloadFactory = payloadFactory;
        this.list = factory.callWithResultSets("comercial", "PA_IncidenciaOperativa_Sel_Listado", "items");
        this.get = factory.callWithResultSets("comercial", "PA_IncidenciaOperativa_Sel_Detalle", "header", "files");
        this.create = factory.call("comercial", "PA_IncidenciaOperativa_Ins_Registro");
        this.review = factory.call("comercial", "PA_IncidenciaOperativa_Upd_Revision");
        this.resolve = factory.call("comercial", "PA_IncidenciaOperativa_Upd_Resolver");
        this.cancel = factory.call("comercial", "PA_IncidenciaOperativa_Upd_Anular");
    }

    public PersistenceResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents c, SessionIdentity i, RequestMetadata m) {
        var page = c.page();
        var f = page.filtros();
        var filters = map(
                "operativoVentaId", f == null ? null : f.operativoVentaId(),
                "entregaSocioId", f == null ? null : f.entregaSocioId(),
                "estadoIncidencia", f == null ? null : f.estadoIncidencia(),
                "tipoIncidencia", f == null ? null : f.tipoIncidencia(),
                "severidad", f == null ? null : f.severidad(),
                "pagina", page.pagina(),
                "tamanoPagina", page.tamanio()
        );
        var out = executor.executeJson(list, payloadFactory.forQuery(i, m, Map.of("filtros", filters)));
        return PaAdapterSupport.page(out, rows(out, "items"), page.pagina(), page.tamanio(), this::summary, "No se pudieron consultar las incidencias.");
    }

    public PersistenceResult<IncidentModels.Detail> get(IncidentCommands.GetIncident c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(get, payloadFactory.forQuery(i, m, Map.of("incidencia", Map.of("incidenciaId", c.incidenciaId()))));
        if (!PaAdapterSupport.success(out)) return PersistenceResult.error(PaAdapterSupport.message(out, "No se pudo consultar la incidencia."));
        var row = one(out, "header");
        if (row == null) return PersistenceResult.error("La incidencia seleccionada no está disponible.");
        return PersistenceResult.ok(
                PaAdapterSupport.message(out, "Incidencia consultada correctamente."),
                new IncidentModels.Detail(summary(row), rows(out, "files").stream().map(this::attachment).toList())
        );
    }

    public PersistenceResult<Long> create(IncidentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(create, payloadFactory.forWrite(i, m, c, Map.of("incidencia", map(
                "operativoVentaId", c.operativoVentaId(),
                "entregaSocioId", c.entregaSocioId(),
                "tipoIncidencia", c.tipoIncidencia(),
                "pesoAfectadoKg", c.pesoAfectadoKg(),
                "severidad", c.severidad(),
                "descripcion", c.descripcion()
        ))));
        return PaAdapterSupport.result(out, SqlValues.longValue(out, "nIncidenciaId"), "No se pudo registrar la incidencia.");
    }

    public PersistenceResult<Void> review(IncidentCommands.Review c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(review, payloadFactory.forWrite(i, m, c, Map.of("incidencia", map(
                "incidenciaId", c.incidenciaId(),
                "pesoAfectadoKg", c.pesoAfectadoKg(),
                "severidad", c.severidad(),
                "descripcion", c.descripcion()
        ))));
        return PaAdapterSupport.result(out, null, "No se pudo actualizar la incidencia.");
    }

    public PersistenceResult<Void> resolve(IncidentCommands.Resolve c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(resolve, payloadFactory.forWrite(i, m, c, Map.of("incidencia", map(
                "incidenciaId", c.incidenciaId(),
                "motivo", c.motivo()
        ))));
        return PaAdapterSupport.result(out, null, "No se pudo resolver la incidencia.");
    }

    public PersistenceResult<Void> cancel(IncidentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        var out = executor.executeJson(cancel, payloadFactory.forWrite(i, m, c, Map.of("incidencia", map(
                "incidenciaId", c.incidenciaId(),
                "motivo", c.motivo()
        ))));
        return PaAdapterSupport.result(out, null, "No se pudo anular la incidencia.");
    }

    private IncidentModels.Summary summary(Map<String, Object> r) {
        return new IncidentModels.Summary(
                SqlValues.longValue(r, "incidenciaId"),
                SqlValues.longValue(r, "operativoVentaId"),
                SqlValues.string(r, "operativo"),
                SqlValues.longValue(r, "entregaSocioId"),
                SqlValues.string(r, "codigoLote"),
                SqlValues.string(r, "tipoIncidencia"),
                SqlValues.instant(r, "fechaHora"),
                SqlValues.decimal(r, "pesoAfectadoKg"),
                SqlValues.string(r, "severidad"),
                SqlValues.string(r, "descripcion"),
                SqlValues.string(r, "estadoIncidencia")
        );
    }

    private IncidentModels.Attachment attachment(Map<String, Object> r) {
        return new IncidentModels.Attachment(
                SqlValues.longValue(r, "archivoId"),
                SqlValues.string(r, "nombreOriginal"),
                SqlValues.string(r, "mimeType"),
                SqlValues.string(r, "secureUrl"),
                SqlValues.string(r, "categoria"),
                SqlValues.string(r, "descripcion")
        );
    }

    private List<Map<String,Object>> rows(Map<String,Object> out, String key) {
        return new PaResultSets(out).rows(key);
    }

    private Map<String,Object> one(Map<String,Object> out, String key) {
        return new PaResultSets(out).one(key).orElse(null);
    }

    private static Map<String,Object> map(Object... values) {
        Map<String,Object> result = new LinkedHashMap<>();
        for (int n = 0; n < values.length; n += 2) if (values[n + 1] != null) result.put((String) values[n], values[n + 1]);
        return result;
    }
}
