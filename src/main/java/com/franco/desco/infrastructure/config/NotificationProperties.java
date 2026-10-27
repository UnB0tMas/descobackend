package com.franco.desco.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(
        prefix = "app.notifications"
)
public record NotificationProperties(
        boolean workerEnabled,
        long fixedDelayMs
) {
}
