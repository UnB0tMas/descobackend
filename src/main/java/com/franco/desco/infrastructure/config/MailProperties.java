package com.franco.desco.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(
        prefix = "app.mail"
)
public record MailProperties(
        String from,
        String fromName,
        String replyTo,
        String companyName,
        String unitName,
        String supportEmail
) {
}
