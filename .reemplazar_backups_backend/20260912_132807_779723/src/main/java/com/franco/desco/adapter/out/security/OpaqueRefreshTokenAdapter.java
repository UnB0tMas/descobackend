package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.RefreshTokenPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

@Component
public class OpaqueRefreshTokenAdapter
        implements RefreshTokenPort {

    private final SecureRandom secureRandom =
            new SecureRandom();

    private final int tokenBytes;

    public OpaqueRefreshTokenAdapter(
            SecurityProperties properties
    ) {
        this.tokenBytes =
                properties.refreshTokenBytes();
    }

    @Override
    public PendingRefreshToken generate() {
        byte[] bytes = new byte[tokenBytes];
        secureRandom.nextBytes(bytes);

        String secret =
                Base64.getUrlEncoder()
                        .withoutPadding()
                        .encodeToString(bytes);

        return new PendingRefreshToken(
                secret,
                sha256Hex(secret)
        );
    }

    @Override
    public ParsedRefreshToken parse(
            String composedToken
    ) {
        if (composedToken == null
                || composedToken.isBlank()) {
            throw new IllegalArgumentException(
                    "Refresh token inválido."
            );
        }

        int separator =
                composedToken.indexOf('.');

        if (separator <= 0
                || separator >=
                composedToken.length() - 1) {
            throw new IllegalArgumentException(
                    "Refresh token inválido."
            );
        }

        UUID sessionPublicId =
                UUID.fromString(
                        composedToken.substring(
                                0,
                                separator
                        )
                );

        String secret =
                composedToken.substring(
                        separator + 1
                );

        return new ParsedRefreshToken(
                sessionPublicId,
                secret,
                sha256Hex(secret)
        );
    }

    @Override
    public String compose(
            UUID sessionPublicId,
            String secret
    ) {
        return sessionPublicId
                + "."
                + secret;
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest digest =
                    MessageDigest.getInstance(
                            "SHA-256"
                    );

            return HexFormat.of()
                    .formatHex(
                            digest.digest(
                                    value.getBytes(
                                            StandardCharsets.UTF_8
                                    )
                            )
                    );

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No fue posible proteger el refresh token.",
                    exception
            );
        }
    }
}
