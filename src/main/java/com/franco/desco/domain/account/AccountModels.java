package com.franco.desco.domain.account;

import java.time.Instant;
import java.util.UUID;

public final class AccountModels {
    private AccountModels() {}

    public record SessionInfo(
            UUID sesionPublicaId,
            Instant fechaCreacionUtc,
            Instant fechaUltimaActividadUtc,
            Instant fechaExpiracionRenovacionUtc,
            String ipCreacion,
            String ipUltimaActividad,
            boolean sesionActual,
            boolean activa,
            Long dispositivoUsuarioId,
            String navegador,
            String sistemaOperativo,
            Instant fechaPrimeraDeteccionUtc,
            Instant fechaUltimaActividadDispositivoUtc,
            boolean reconocido
    ) {}

    public record DeviceInfo(
            Long dispositivoUsuarioId,
            String navegador,
            String sistemaOperativo,
            Instant fechaPrimeraDeteccionUtc,
            Instant fechaUltimaActividadUtc,
            String ultimaIp,
            boolean reconocidoVigente,
            Instant fechaReconocimientoUtc,
            Instant fechaExpiracionReconocimientoUtc,
            boolean dispositivoActual
    ) {}

    public record EmailChangeIssue(
            Long usuarioCorreoSeguridadId,
            Long codigoUnSoloUsoId,
            Long notificacionSeguridadId,
            String correoDestino,
            boolean debeEnviar
    ) {}
}
