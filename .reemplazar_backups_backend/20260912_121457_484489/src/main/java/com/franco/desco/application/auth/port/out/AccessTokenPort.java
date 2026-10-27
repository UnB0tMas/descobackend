package com.franco.desco.application.auth.port.out;

import com.franco.desco.domain.auth.AccessContext;

import java.time.Instant;

public interface AccessTokenPort {

    IssuedAccessToken issue(AccessContext context);

    record IssuedAccessToken(
            String token,
            Instant expiresAt
    ) {
    }
}
