package com.franco.desco.adapter.out.crypto;

import com.franco.desco.application.auth.port.out.RefreshTokenPort;
import com.franco.desco.application.shared.port.out.RequestHashPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.UUID;

@Component
public final class RefreshTokenAdapter
        implements RefreshTokenPort {

    private static final String SEPARATOR = ".";

    private final SecurityProperties properties;
    private final RequestHashPort requestHash;
    private final SecureRandom random =
            new SecureRandom();

    public RefreshTokenAdapter(
            SecurityProperties properties,
            RequestHashPort requestHash
    ) {
        this.properties = properties;
        this.requestHash = requestHash;
    }

    @Override
    public PendingRefreshToken generate() {
        int bytes =
                Math.max(
                        32,
                        Math.min(
                                96,
                                properties.refreshTokenBytes()
                        )
                );

        byte[] value =
                new byte[bytes];

        random.nextBytes(value);

        String secret =
                Base64.getUrlEncoder()
                        .withoutPadding()
                        .encodeToString(value);

        return new PendingRefreshToken(
                secret,
                requestHash.sha256Hex(secret)
        );
    }

    @Override
    public ParsedRefreshToken parse(String token) {
        if (token == null
                || token.isBlank()) {
            throw new IllegalArgumentException(
                    "Token vacío."
            );
        }

        String[] parts =
                token.trim()
                        .split("\\.", 2);

        if (parts.length != 2) {
            throw new IllegalArgumentException(
                    "Token inválido."
            );
        }

        UUID sessionId =
                UUID.fromString(parts[0]);

        String secret =
                parts[1].trim();

        if (secret.length() < 32) {
            throw new IllegalArgumentException(
                    "Token inválido."
            );
        }

        return new ParsedRefreshToken(
                sessionId,
                secret,
                requestHash.sha256Hex(secret)
        );
    }

    @Override
    public String compose(
            UUID sessionPublicId,
            String secret
    ) {
        if (sessionPublicId == null
                || secret == null
                || secret.isBlank()) {
            throw new IllegalArgumentException(
                    "No se pudo crear el token de renovación."
            );
        }

        return sessionPublicId
                + SEPARATOR
                + secret.trim();
    }
}
