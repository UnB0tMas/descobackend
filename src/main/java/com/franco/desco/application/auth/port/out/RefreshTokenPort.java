package com.franco.desco.application.auth.port.out;

import java.util.UUID;

public interface RefreshTokenPort {

    PendingRefreshToken generate();

    ParsedRefreshToken parse(String token);

    String compose(
            UUID sessionPublicId,
            String secret
    );

    record PendingRefreshToken(
            String secret,
            String hashHex
    ) {
    }

    record ParsedRefreshToken(
            UUID sessionPublicId,
            String secret,
            String hashHex
    ) {
    }
}
