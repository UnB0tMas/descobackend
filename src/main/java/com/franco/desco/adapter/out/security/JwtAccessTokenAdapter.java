package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.AccessTokenPort;
import com.franco.desco.domain.auth.AccessContext;
import com.franco.desco.domain.auth.AccessRole;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
public final class JwtAccessTokenAdapter
        implements AccessTokenPort {

    private final JwtEncoder encoder;
    private final SecurityProperties properties;

    public JwtAccessTokenAdapter(
            JwtEncoder encoder,
            SecurityProperties properties
    ) {
        this.encoder = encoder;
        this.properties = properties;
    }

    @Override
    public IssuedAccessToken issue(
            AccessContext context
    ) {
        if (context == null
                || context.usuario() == null
                || context.usuario().usuarioId() == null
                || context.usuario().sesionPublicaId() == null) {
            throw new IllegalArgumentException(
                    "No se pudo emitir la sesión."
            );
        }

        Instant issuedAt =
                Instant.now();

        Instant expiresAt =
                issuedAt.plus(
                        properties.accessTokenTtl()
                );

        List<String> roles =
                context.roles()
                        .stream()
                        .map(AccessRole::codigo)
                        .filter(value ->
                                value != null
                                        && !value.isBlank()
                        )
                        .distinct()
                        .toList();

        JwtClaimsSet claims =
                JwtClaimsSet.builder()
                        .issuer(properties.issuer())
                        .subject(
                                context.usuario()
                                        .usuarioId()
                                        .toString()
                        )
                        .audience(
                                List.of(
                                        properties.audience()
                                )
                        )
                        .issuedAt(issuedAt)
                        .expiresAt(expiresAt)
                        .id(
                                UUID.randomUUID()
                                        .toString()
                        )
                        .claim(
                                "username",
                                context.usuario()
                                        .nombreUsuario()
                        )
                        .claim(
                                "sid",
                                context.usuario()
                                        .sesionPublicaId()
                                        .toString()
                        )
                        .claim(
                                "tv",
                                context.usuario()
                                        .tokenVersion()
                        )
                        .claim(
                                "roles",
                                roles
                        )
                        .claim(
                                "token_type",
                                "access"
                        )
                        .build();

        String token =
                encoder.encode(
                        JwtEncoderParameters.from(
                                claims
                        )
                ).getTokenValue();

        return new IssuedAccessToken(
                token,
                expiresAt
        );
    }
}
