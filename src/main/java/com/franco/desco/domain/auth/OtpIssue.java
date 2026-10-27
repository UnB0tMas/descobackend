package com.franco.desco.domain.auth;

public record OtpIssue(
        Long codigoUnSoloUsoId,
        Long notificacionSeguridadId,
        String correoDestino,
        boolean debeEnviar,
        boolean exitoso,
        String mensaje
) {
}
