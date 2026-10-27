package com.franco.desco.application.auth.port.out;

public interface SecurityNotificationPort {
    void markResult(
            Long securityNotificationId,
            String result,
            String detail
    );
}
