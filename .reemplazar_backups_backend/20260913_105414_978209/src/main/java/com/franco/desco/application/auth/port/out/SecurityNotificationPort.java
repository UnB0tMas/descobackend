package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.SecurityNotification;

import java.util.List;

public interface SecurityNotificationPort {

    /*
     * Se deja como default para conservar compatibilidad con adapters
     * antiguos que únicamente actualizaban el resultado de envío.
     * El adapter SQL dedicado lo sobrescribe y es el bean primario.
     */
    default List<SecurityNotification> pending(
            int limit
    ) {
        return List.of();
    }

    void markResult(
            Long securityNotificationId,
            String result,
            String detail
    );
}
