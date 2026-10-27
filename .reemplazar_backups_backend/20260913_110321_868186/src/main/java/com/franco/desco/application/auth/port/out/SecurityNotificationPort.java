package com.franco.desco.application.auth.port.out;

import java.util.UUID;

public interface SecurityNotificationPort {

    Long registerNewDevice(
            Long userId,
            String destination,
            String browser,
            String operatingSystem,
            String ip,
            UUID correlationId
    );

    void markResult(
            Long securityNotificationId,
            String result,
            String detail
    );
}
