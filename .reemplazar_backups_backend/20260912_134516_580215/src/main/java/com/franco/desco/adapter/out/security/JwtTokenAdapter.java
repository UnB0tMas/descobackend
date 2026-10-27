package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.AccessTokenPort;
import com.franco.desco.domain.auth.AccessContext;
import com.franco.desco.domain.auth.AccessRole;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
public class JwtTokenAdapter
        implements AccessTokenPort {

    private final JwtEncoder jwtEncoder;
    private final SecurityProperties properties;

    public JwtTokenAdapter(
            JwtEncoder jwtEncoder,
            SecurityProperties properties
    ) {
        this.jwtEncoder = jwtEncoder;
        this.properties = properties;
    }

    @Override
    public IssuedAccessToken issue(
            AccessContext context
    ) {
        Instant now = Instant.now();

        Instant expiresAt =
                now.plus(
                        properties.accessTokenTtl()
                );

        UUID jti = UUID.randomUUID();

        List<String> roles =
                context.roles()
                        .stream()
                        .map(AccessRole::codigo)
                        .toList();

        JwtClaimsSet claims =
                JwtClaimsSet.builder()
                        .issuer(
                                properties.issuer()
                        )
                        .audience(
                                List.of(
                                        properties.audience()
                                )
                        )
                        .subject(
                                String.valueOf(
                                        context.usuario()
                                                .usuarioId()
                                )
                        )
                        .issuedAt(now)
                        .expiresAt(expiresAt)
                        .id(jti.toString())
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
                                "username",
                                context.usuario()
                                        .nombreUsuario()
                        )
                        .claim("roles", roles)
                        .claim(
                                "token_type",
                                "access"
                        )
                        .build();

        JwsHeader header =
                JwsHeader.with(
                                MacAlgorithm.HS512
                        )
                        .type("JWT")
                        .build();

        String token =
                jwtEncoder.encode(
                                JwtEncoderParameters.from(
                                        header,
                                        claims
                                )
                        )
                        .getTokenValue();

        return new IssuedAccessToken(
                token,
                expiresAt
        );
    }
}
