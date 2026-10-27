package com.franco.desco.adapter.in.web.account;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.UUID;

public final class AccountResponses {
    private AccountResponses() {}

    @Schema(name = "AccountSessionResponse")
    public record Session(
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

    @Schema(name = "AccountDeviceResponse")
    public record Device(
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
}
