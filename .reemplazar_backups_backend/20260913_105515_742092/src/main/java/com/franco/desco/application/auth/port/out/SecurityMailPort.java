package com.franco.desco.application.auth.port.out;

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

    void sendNewDevice(
            String destination,
            String browser,
            String operatingSystem,
            String ip
    );
}
