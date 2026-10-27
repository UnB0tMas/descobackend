package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.SecurityNotification;

public interface SecurityMailPort {

    void sendEmailVerification(
            String destination,
            String username,
            String code
    );

    void sendTwoFactor(
            String destination,
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

    void sendSecurityNotification(SecurityNotification notification);
}
