package com.franco.desco.domain.audit;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class AuditModels {
    private AuditModels() {}

    public record Summary(
            Long auditoriaEventoId, Instant fechaHoraUtc, Long usuarioId, String nombreUsuario, String nombrePersona,
            Integer moduloId, String codigoModulo, String nombreModulo, String accion, String esquemaEntidad,
            String nombreEntidad, String identificador, String motivo, String resultado, String endpoint, String ip,
            Long sesionUsuarioId, Long dispositivoUsuarioId, UUID correlacionId, UUID solicitudId
    ) {}

    public record Event(
            Long auditoriaEventoId, Instant fechaHoraUtc, Long usuarioId, String nombreUsuario, String nombrePersona,
            Integer moduloId, String codigoModulo, String nombreModulo, String accion, String esquemaEntidad,
            String nombreEntidad, String identificador, String motivo, String resultado, String endpoint, String ip,
            Long sesionUsuarioId, UUID sesionPublicaId, Long dispositivoUsuarioId, String navegador,
            String sistemaOperativo, String userAgent, boolean dispositivoReconocido, UUID correlacionId,
            UUID solicitudId, String datosAnteriores, String datosPosteriores
    ) {}

    public record Transition(Long transicionEstadoId,String campoEstado,String estadoAnterior,String estadoNuevo,String motivo,Instant fechaHoraUtc) {}

    public record Detail(Event evento,List<Transition> transiciones) {
        public Detail { transiciones = transiciones == null ? List.of() : List.copyOf(transiciones); }
    }

    public record ExportRow(
            Long auditoriaEventoId,Instant fechaHoraUtc,Long usuarioId,String nombreUsuario,String nombrePersona,
            Integer moduloId,String codigoModulo,String modulo,String accion,String esquemaEntidad,String nombreEntidad,
            String identificador,String motivo,String resultado,String endpoint,String ip,UUID sesionPublicaId,
            Long dispositivoUsuarioId,String navegador,String sistemaOperativo,boolean dispositivoReconocido,
            UUID correlacionId,UUID solicitudId
    ) {}
}
