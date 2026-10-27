package com.franco.desco.domain.auth;

import java.time.Instant;
import java.util.UUID;

public record SecurityNotification(
        Long notificacionSeguridadId,
        Long usuarioId,
        String tipoNotificacion,
        String correoDestino,
        Instant fechaCreacionUtc,
        Integer cantidadIntentos,
        UUID correlacionId,
        String metadata
) {
}
