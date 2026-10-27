package com.franco.desco.adapter.in.security;

import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Objects;
import java.util.UUID;

@Component
public class JwtSessionIdentityResolver {

    public SessionIdentity resolve(
            JwtAuthenticationToken authentication
    ) {
        Objects.requireNonNull(
                authentication,
                "La autenticación JWT es obligatoria."
        );

        return resolve(authentication.getToken());
    }

    public SessionIdentity resolve(Jwt jwt) {
        Objects.requireNonNull(
                jwt,
                "El JWT es obligatorio."
        );

        Long usuarioId = requiredLong(
                jwt.getSubject(),
                "sub"
        );

        UUID sesionPublicaId = requiredUuid(
                jwt.getClaimAsString("sid"),
                "sid"
        );

        /*
         * No usar:
         *
         *     Integer tokenVersion = jwt.getClaim("tv");
         *
         * Los claims JSON numéricos pueden ser materializados por Nimbus
         * como distintos subtipos de Number (Integer, Long, etc.).
         * Una asignación genérica directa puede provocar ClassCastException
         * aunque el valor del claim sea perfectamente válido.
         */
        Integer tokenVersion = requiredInteger(
                jwt.getClaims().get("tv"),
                "tv"
        );

        String jti = requiredText(
                jwt.getId(),
                "jti"
        );

        return new SessionIdentity(
                usuarioId,
                sesionPublicaId,
                tokenVersion,
                jti
        );
    }

    private Long requiredLong(
            Object value,
            String claimName
    ) {
        if (value instanceof Number number) {
            return number.longValue();
        }

        String text = normalizedText(value);

        if (text == null) {
            throw invalidClaim(claimName);
        }

        try {
            return Long.valueOf(text);
        } catch (NumberFormatException exception) {
            throw invalidClaim(claimName);
        }
    }

    private Integer requiredInteger(
            Object value,
            String claimName
    ) {
        if (value instanceof Number number) {
            long parsed = number.longValue();

            if (
                    parsed < Integer.MIN_VALUE
                    || parsed > Integer.MAX_VALUE
            ) {
                throw invalidClaim(claimName);
            }

            return Math.toIntExact(parsed);
        }

        String text = normalizedText(value);

        if (text == null) {
            throw invalidClaim(claimName);
        }

        try {
            return Integer.valueOf(text);
        } catch (NumberFormatException exception) {
            throw invalidClaim(claimName);
        }
    }

    private UUID requiredUuid(
            Object value,
            String claimName
    ) {
        String text = normalizedText(value);

        if (text == null) {
            throw invalidClaim(claimName);
        }

        try {
            return UUID.fromString(text);
        } catch (IllegalArgumentException exception) {
            throw invalidClaim(claimName);
        }
    }

    private String requiredText(
            Object value,
            String claimName
    ) {
        String text = normalizedText(value);

        if (text == null) {
            throw invalidClaim(claimName);
        }

        return text;
    }

    private String normalizedText(Object value) {
        if (value == null) {
            return null;
        }

        String text = value.toString().trim();

        return text.isEmpty()
                ? null
                : text;
    }

    private IllegalArgumentException invalidClaim(
            String claimName
    ) {
        return new IllegalArgumentException(
                "El token de acceso no contiene una identidad de sesión válida: "
                        + claimName
        );
    }
}
