package com.franco.desco.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(
        prefix = "app.security"
)
public record SecurityProperties(
        String issuer,
        String audience,
        Duration accessTokenTtl,
        String jwtSecretBase64,
        String otpHmacSecretBase64,
        String deviceHmacSecretBase64,
        String dummyPasswordHash,
        int otpDigits,
        int refreshTokenBytes
) {
}
