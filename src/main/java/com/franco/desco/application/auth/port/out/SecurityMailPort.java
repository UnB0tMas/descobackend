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

    /**
     * Contrato conservado para SecurityNotificationWorker y para el adapter
     * Thymeleaf existente.
     */
    void sendSecurityNotification(
            SecurityNotification notification
    );

    /**
     * Envío inmediato utilizado por el flujo de autenticación. Se mantiene
     * como default para que implementaciones legacy basadas en la cola sigan
     * siendo compatibles; el adapter canónico sobrescribe este método.
     */
    default void sendNewDevice(
            String destination,
            String browser,
            String operatingSystem,
            String ip
    ) {
        throw new UnsupportedOperationException(
                "El adaptador de correo no implementa envío inmediato de nuevo dispositivo."
        );
    }
}
