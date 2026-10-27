package com.franco.desco.adapter.in.web.audit;

import com.franco.desco.application.audit.AuditCommands.*;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.audit.AuditModels;
import org.springframework.stereotype.Component;
import java.time.LocalDate;

@Component
public class AuditWebMapper {
    public Filter filter(LocalDate from,LocalDate to,Long user,Integer module,String action,String schema,String entity,String result){return new Filter(from,to,user,module,action,schema,entity,result);}
    public ListAudit list(int p,int s,Filter f){return new ListAudit(new PageRequest<>(p,s,f,null,null));}
    public GetAudit get(Long id){return new GetAudit(id);}
    public ExportAudit export(Filter f){return new ExportAudit(f);}

    public AuditResponses.Summary response(AuditModels.Summary x){return new AuditResponses.Summary(x.auditoriaEventoId(),x.fechaHoraUtc(),x.usuarioId(),x.nombreUsuario(),x.nombrePersona(),x.moduloId(),x.codigoModulo(),x.nombreModulo(),x.accion(),x.esquemaEntidad(),x.nombreEntidad(),x.identificador(),x.motivo(),x.resultado(),x.endpoint(),x.ip(),x.sesionUsuarioId(),x.dispositivoUsuarioId(),x.correlacionId(),x.solicitudId());}
    public AuditResponses.Event response(AuditModels.Event x){return new AuditResponses.Event(x.auditoriaEventoId(),x.fechaHoraUtc(),x.usuarioId(),x.nombreUsuario(),x.nombrePersona(),x.moduloId(),x.codigoModulo(),x.nombreModulo(),x.accion(),x.esquemaEntidad(),x.nombreEntidad(),x.identificador(),x.motivo(),x.resultado(),x.endpoint(),x.ip(),x.sesionUsuarioId(),x.sesionPublicaId(),x.dispositivoUsuarioId(),x.navegador(),x.sistemaOperativo(),x.userAgent(),x.dispositivoReconocido(),x.correlacionId(),x.solicitudId(),x.datosAnteriores(),x.datosPosteriores());}
    public AuditResponses.Transition response(AuditModels.Transition x){return new AuditResponses.Transition(x.transicionEstadoId(),x.campoEstado(),x.estadoAnterior(),x.estadoNuevo(),x.motivo(),x.fechaHoraUtc());}
    public AuditResponses.Detail response(AuditModels.Detail x){return new AuditResponses.Detail(response(x.evento()),x.transiciones().stream().map(this::response).toList());}
    public AuditResponses.ExportRow response(AuditModels.ExportRow x){return new AuditResponses.ExportRow(x.auditoriaEventoId(),x.fechaHoraUtc(),x.usuarioId(),x.nombreUsuario(),x.nombrePersona(),x.moduloId(),x.codigoModulo(),x.modulo(),x.accion(),x.esquemaEntidad(),x.nombreEntidad(),x.identificador(),x.motivo(),x.resultado(),x.endpoint(),x.ip(),x.sesionPublicaId(),x.dispositivoUsuarioId(),x.navegador(),x.sistemaOperativo(),x.dispositivoReconocido(),x.correlacionId(),x.solicitudId());}
}
