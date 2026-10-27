package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.SecurityNotification;

import java.util.List;

public interface SecurityNotificationPort {

    List<SecurityNotification> pending(int limit);

    void markResult(
            Long notificationId,
            String status,
            String providerMessageId
    );
}
