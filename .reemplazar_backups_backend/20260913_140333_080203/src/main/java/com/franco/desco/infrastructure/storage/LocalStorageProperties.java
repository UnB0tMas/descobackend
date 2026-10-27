package com.franco.desco.infrastructure.storage;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "app.storage")
public record LocalStorageProperties(
        String root,
        long maxFileBytes,
        Duration temporaryRetention
) {
    public LocalStorageProperties {
        if (root == null || root.isBlank()) root = "./storage";
        if (maxFileBytes <= 0) maxFileBytes = 25L * 1024L * 1024L;
        if (temporaryRetention == null || temporaryRetention.isNegative() || temporaryRetention.isZero()) {
            temporaryRetention = Duration.ofHours(24);
        }
    }
}
