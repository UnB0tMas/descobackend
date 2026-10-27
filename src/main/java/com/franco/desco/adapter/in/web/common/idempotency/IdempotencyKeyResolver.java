package com.franco.desco.adapter.in.web.common.idempotency;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class IdempotencyKeyResolver {

    public static final String HEADER =
            "X-Idempotency-Key";

    public static final String ATTRIBUTE =
            IdempotencyKeyResolver.class.getName()
                    + ".IDEMPOTENCY_KEY";

    public UUID optional(
            HttpServletRequest request
    ) {
        Object stored = request.getAttribute(
                ATTRIBUTE
        );

        if (stored instanceof UUID uuid) {
            return uuid;
        }

        String raw = request.getHeader(HEADER);

        if (raw == null || raw.isBlank()) {
            return null;
        }

        UUID parsed = parse(raw);
        request.setAttribute(
                ATTRIBUTE,
                parsed
        );
        return parsed;
    }

    public UUID required(
            HttpServletRequest request
    ) {
        UUID value = optional(request);

        if (value == null) {
            throw new IdempotencyKeyException(
                    "Envíe una clave de idempotencia para procesar esta operación."
            );
        }

        return value;
    }

    private UUID parse(String raw) {
        try {
            return UUID.fromString(
                    raw.trim()
            );
        } catch (IllegalArgumentException exception) {
            throw new IdempotencyKeyException(
                    "La clave de idempotencia enviada no es válida."
            );
        }
    }
}
