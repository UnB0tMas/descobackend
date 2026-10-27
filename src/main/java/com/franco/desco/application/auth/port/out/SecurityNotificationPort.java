package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.SecurityNotification;

import java.util.List;
import java.util.UUID;

public interface SecurityNotificationPort {

    /**
     * Compatibilidad con el worker asíncrono existente.
     * Devuelve notificaciones que siguen pendientes de entrega.
     */
    List<SecurityNotification> pending(int limit);

    /**
     * Registra la alerta asociada a una huella de dispositivo detectada por
     * primera vez. Los adapters legacy que solo consumen la cola no necesitan
     * implementar esta operación.
     */
    default Long registerNewDevice(
            Long userId,
            String destination,
            String browser,
            String operatingSystem,
            String ip,
            UUID correlationId
    ) {
        return null;
    }

    void markResult(
            Long securityNotificationId,
            String result,
            String detail
    );
}
