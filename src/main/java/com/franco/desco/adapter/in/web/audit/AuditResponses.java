package com.franco.desco.adapter.in.web.audit;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class AuditResponses {
    private AuditResponses() {}

    @Schema(name="AuditSummaryResponse")
    public record Summary(Long auditoriaEventoId,Instant fechaHoraUtc,Long usuarioId,String nombreUsuario,String nombrePersona,Integer moduloId,String codigoModulo,String nombreModulo,String accion,String esquemaEntidad,String nombreEntidad,String identificador,String motivo,String resultado,String endpoint,String ip,Long sesionUsuarioId,Long dispositivoUsuarioId,UUID correlacionId,UUID solicitudId){}

    @Schema(name="AuditEventResponse")
    public record Event(Long auditoriaEventoId,Instant fechaHoraUtc,Long usuarioId,String nombreUsuario,String nombrePersona,Integer moduloId,String codigoModulo,String nombreModulo,String accion,String esquemaEntidad,String nombreEntidad,String identificador,String motivo,String resultado,String endpoint,String ip,Long sesionUsuarioId,UUID sesionPublicaId,Long dispositivoUsuarioId,String navegador,String sistemaOperativo,String userAgent,boolean dispositivoReconocido,UUID correlacionId,UUID solicitudId,String datosAnteriores,String datosPosteriores){}

    @Schema(name="AuditTransitionResponse")
    public record Transition(Long transicionEstadoId,String campoEstado,String estadoAnterior,String estadoNuevo,String motivo,Instant fechaHoraUtc){}

    @Schema(name="AuditDetailResponse")
    public record Detail(Event evento,List<Transition>transiciones){}

    @Schema(name="AuditExportRowResponse")
    public record ExportRow(Long auditoriaEventoId,Instant fechaHoraUtc,Long usuarioId,String nombreUsuario,String nombrePersona,Integer moduloId,String codigoModulo,String modulo,String accion,String esquemaEntidad,String nombreEntidad,String identificador,String motivo,String resultado,String endpoint,String ip,UUID sesionPublicaId,Long dispositivoUsuarioId,String navegador,String sistemaOperativo,boolean dispositivoReconocido,UUID correlacionId,UUID solicitudId){}
}
