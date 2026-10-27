package com.franco.desco.adapter.out.sqlserver.audit;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.audit.AuditCommands;
import com.franco.desco.application.audit.port.out.AuditPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.audit.AuditModels;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;
import java.util.*;

@Component
public class AuditSqlServerAdapter implements AuditPersistencePort {
    private final SqlServerPaExecutor executor;private final PaPayloadFactory payloadFactory;
    private final SimpleJdbcCall list,get,export;

    public AuditSqlServerAdapter(SqlServerPaFactory f,SqlServerPaExecutor e,PaPayloadFactory p){
        executor=e;payloadFactory=p;
        list=f.callWithResultSets("auditoria","PA_Auditoria_Sel_Listado","items");
        get=f.callWithResultSets("auditoria","PA_Auditoria_Sel_Detalle","header","transitions");
        export=f.callWithResultSets("auditoria","PA_Auditoria_Sel_Exportacion","items");
    }

    public PersistenceResult<PageResult<AuditModels.Summary>> list(AuditCommands.ListAudit c,SessionIdentity i,RequestMetadata m){
        var pg=c.page();var f=pg.filtros();
        var body=new LinkedHashMap<String,Object>();
        body.put("filtros",filters(f));
        body.put("paginacion",Map.of("pagina",pg.pagina(),"tamano",pg.tamanio()));
        var out=executor.executeJson(list,payloadFactory.forQuery(i,m,body));
        return PaAdapterSupport.page(out,rows(out,"items"),pg.pagina(),pg.tamanio(),this::summary,"No se pudo consultar la auditoría.");
    }

    public PersistenceResult<AuditModels.Detail> get(AuditCommands.GetAudit c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(get,payloadFactory.forQuery(i,m,Map.of("auditoria",Map.of("auditoriaEventoId",c.auditoriaEventoId()))));
        if(!PaAdapterSupport.success(out))return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo consultar el evento de auditoría."));
        var h=one(out,"header");if(h==null)return PersistenceResult.error("El evento de auditoría no está disponible.");
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Evento consultado correctamente."),new AuditModels.Detail(event(h),rows(out,"transitions").stream().map(this::transition).toList()));
    }

    public PersistenceResult<List<AuditModels.ExportRow>> export(AuditCommands.ExportAudit c,SessionIdentity i,RequestMetadata m){
        var out=executor.executeJson(export,payloadFactory.forQuery(i,m,Map.of("filtros",filters(c.filtros()))));
        if(!PaAdapterSupport.success(out))return PersistenceResult.error(PaAdapterSupport.message(out,"No se pudo preparar la exportación de auditoría."));
        return PersistenceResult.ok(PaAdapterSupport.message(out,"Exportación de auditoría preparada correctamente."),rows(out,"items").stream().map(this::exportRow).toList());
    }

    private Map<String,Object> filters(AuditCommands.Filter f){return map(
            "fechaDesde",f==null?null:f.fechaDesde(),"fechaHasta",f==null?null:f.fechaHasta(),"usuarioId",f==null?null:f.usuarioId(),
            "moduloId",f==null?null:f.moduloId(),"accion",f==null?null:f.accion(),"esquemaEntidad",f==null?null:f.esquemaEntidad(),
            "nombreEntidad",f==null?null:f.nombreEntidad(),"resultado",f==null?null:f.resultado()
    );}

    private AuditModels.Summary summary(Map<String,Object>r){return new AuditModels.Summary(
            SqlValues.longValue(r,"auditoriaEventoId"),SqlValues.instant(r,"fechaHoraUtc"),SqlValues.longValue(r,"usuarioId"),SqlValues.string(r,"nombreUsuario"),SqlValues.string(r,"nombrePersona"),
            SqlValues.intValue(r,"moduloId"),SqlValues.string(r,"codigoModulo"),SqlValues.string(r,"nombreModulo"),SqlValues.string(r,"accion"),SqlValues.string(r,"esquemaEntidad"),
            SqlValues.string(r,"nombreEntidad"),SqlValues.string(r,"identificador"),SqlValues.string(r,"motivo"),SqlValues.string(r,"resultado"),SqlValues.string(r,"endpoint"),SqlValues.string(r,"ip"),
            SqlValues.longValue(r,"sesionUsuarioId"),SqlValues.longValue(r,"dispositivoUsuarioId"),SqlValues.uuid(r,"correlacionId"),SqlValues.uuid(r,"solicitudId")
    );}

    private AuditModels.Event event(Map<String,Object>r){return new AuditModels.Event(
            SqlValues.longValue(r,"auditoriaEventoId"),SqlValues.instant(r,"fechaHoraUtc"),SqlValues.longValue(r,"usuarioId"),SqlValues.string(r,"nombreUsuario"),SqlValues.string(r,"nombrePersona"),
            SqlValues.intValue(r,"moduloId"),SqlValues.string(r,"codigoModulo"),SqlValues.string(r,"nombreModulo"),SqlValues.string(r,"accion"),SqlValues.string(r,"esquemaEntidad"),SqlValues.string(r,"nombreEntidad"),
            SqlValues.string(r,"identificador"),SqlValues.string(r,"motivo"),SqlValues.string(r,"resultado"),SqlValues.string(r,"endpoint"),SqlValues.string(r,"ip"),SqlValues.longValue(r,"sesionUsuarioId"),
            SqlValues.uuid(r,"sesionPublicaId"),SqlValues.longValue(r,"dispositivoUsuarioId"),SqlValues.string(r,"navegador"),SqlValues.string(r,"sistemaOperativo"),SqlValues.string(r,"userAgent"),
            SqlValues.bool(r,"dispositivoReconocido"),SqlValues.uuid(r,"correlacionId"),SqlValues.uuid(r,"solicitudId"),SqlValues.string(r,"datosAnteriores"),SqlValues.string(r,"datosPosteriores")
    );}

    private AuditModels.Transition transition(Map<String,Object>r){return new AuditModels.Transition(SqlValues.longValue(r,"transicionEstadoId"),SqlValues.string(r,"campoEstado"),SqlValues.string(r,"estadoAnterior"),SqlValues.string(r,"estadoNuevo"),SqlValues.string(r,"motivo"),SqlValues.instant(r,"fechaHoraUtc"));}

    private AuditModels.ExportRow exportRow(Map<String,Object>r){return new AuditModels.ExportRow(
            SqlValues.longValue(r,"auditoriaEventoId"),SqlValues.instant(r,"fechaHoraUtc"),SqlValues.longValue(r,"usuarioId"),SqlValues.string(r,"nombreUsuario"),SqlValues.string(r,"nombrePersona"),
            SqlValues.intValue(r,"moduloId"),SqlValues.string(r,"codigoModulo"),SqlValues.string(r,"modulo"),SqlValues.string(r,"accion"),SqlValues.string(r,"esquemaEntidad"),SqlValues.string(r,"nombreEntidad"),
            SqlValues.string(r,"identificador"),SqlValues.string(r,"motivo"),SqlValues.string(r,"resultado"),SqlValues.string(r,"endpoint"),SqlValues.string(r,"ip"),SqlValues.uuid(r,"sesionPublicaId"),
            SqlValues.longValue(r,"dispositivoUsuarioId"),SqlValues.string(r,"navegador"),SqlValues.string(r,"sistemaOperativo"),SqlValues.bool(r,"dispositivoReconocido"),SqlValues.uuid(r,"correlacionId"),SqlValues.uuid(r,"solicitudId")
    );}

    private List<Map<String,Object>>rows(Map<String,Object>o,String k){return new PaResultSets(o).rows(k);}
    private Map<String,Object>one(Map<String,Object>o,String k){return new PaResultSets(o).one(k).orElse(null);}
    private static Map<String,Object>map(Object...v){Map<String,Object>m=new LinkedHashMap<>();for(int n=0;n<v.length;n+=2)if(v[n+1]!=null)m.put((String)v[n],v[n+1]);return m;}
}
