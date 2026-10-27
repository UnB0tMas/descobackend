package com.franco.desco.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(
        prefix = "app.frontend"
)
public record FrontendProperties(
        String baseUrl
) {
}
