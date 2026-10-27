package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.application.auth.port.out.SecurityNotificationPort;
import com.franco.desco.domain.auth.SecurityNotification;
import com.franco.desco.infrastructure.config.NotificationProperties;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class SecurityNotificationWorker {

    private final NotificationProperties properties;
    private final SecurityNotificationPort notificationPort;
    private final SecurityMailPort mailPort;

    public SecurityNotificationWorker(
            NotificationProperties properties,
            SecurityNotificationPort notificationPort,
            SecurityMailPort mailPort
    ) {
        this.properties = properties;
        this.notificationPort = notificationPort;
        this.mailPort = mailPort;
    }

    @Scheduled(
            fixedDelayString =
                    "${app.notifications.fixed-delay-ms:10000}"
    )
    public void run() {
        if (!properties.workerEnabled()) {
            return;
        }

        for (SecurityNotification notification
                : notificationPort.pending(20)) {

            try {
                mailPort.sendSecurityNotification(
                        notification
                );

                notificationPort.markResult(
                        notification
                                .notificacionSeguridadId(),
                        "ENVIADO",
                        null
                );

            } catch (RuntimeException exception) {
                notificationPort.markResult(
                        notification
                                .notificacionSeguridadId(),
                        "FALLIDO",
                        null
                );
            }
        }
    }
}
