package com.franco.desco.application.shared;

import java.util.UUID;

public record RequestMetadata(
        UUID correlacionId,
        UUID solicitudId,
        UUID claveIdempotencia,
        String ip,
        String endpoint,
        String userAgent,
        String navegador,
        String sistemaOperativo,
        String deviceId
) {
}
