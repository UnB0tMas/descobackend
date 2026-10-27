package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.SecurityNotification;

public interface SecurityMailPort {

    void sendTwoFactor(
            String destination,
            String code
    );

    void sendEmailVerification(
            String destination,
            String username,
            String code
    );

    void sendPasswordRecovery(
            String destination,
            String username,
            String code
    );

    void sendEmailChangeCode(
            String destination,
            String code
    );

    /*
     * Compatibilidad con adapters SMTP anteriores.
     * ThymeleafSecurityMailAdapter sobrescribe este método.
     */
    default void sendSecurityNotification(
            SecurityNotification notification
    ) {
        throw new UnsupportedOperationException(
                "El adaptador de correo activo no implementa notificaciones de seguridad diferidas."
        );
    }
}
