package com.franco.desco.adapter.in.web.common;

import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyResolver;
import com.franco.desco.application.shared.RequestMetadata;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

import java.util.Locale;
import java.util.UUID;

@Component
public class ClientRequestContextResolver {

    public static final String DEVICE_HEADER = "X-Device-Id";

    private final IdempotencyKeyResolver idempotencyKeyResolver;

    public ClientRequestContextResolver(
            IdempotencyKeyResolver idempotencyKeyResolver
    ) {
        this.idempotencyKeyResolver = idempotencyKeyResolver;
    }

    public RequestMetadata resolve(
            HttpServletRequest request
    ) {
        String userAgent = safe(
                request.getHeader("User-Agent")
        );

        return new RequestMetadata(
                CorrelationIdFilter.correlationId(request),
                UUID.randomUUID(),
                idempotencyKeyResolver.optional(request),
                resolveIp(request),
                request.getRequestURI(),
                userAgent,
                browser(userAgent),
                operatingSystem(userAgent),
                safe(request.getHeader(DEVICE_HEADER))
        );
    }

    /**
     * La configuración actual usa server.forward-headers-strategy=none.
     * Por tanto no debe confiarse en X-Forwarded-For recibido directamente
     * desde Internet, porque el cliente puede falsificarlo.
     *
     * Cuando DESCO se despliegue detrás de un proxy confiable, se debe
     * configurar el soporte de forwarded headers en Spring/proxy y recién
     * entonces utilizar la dirección ya resuelta por el contenedor.
     */
    private String resolveIp(
            HttpServletRequest request
    ) {
        return safe(request.getRemoteAddr());
    }

    private String browser(String userAgent) {
        String ua = userAgent.toLowerCase(Locale.ROOT);

        if (ua.contains("edg/")) {
            return "Microsoft Edge";
        }
        if (ua.contains("chrome/")) {
            return "Google Chrome";
        }
        if (ua.contains("firefox/")) {
            return "Mozilla Firefox";
        }
        if (ua.contains("safari/") && !ua.contains("chrome/")) {
            return "Safari";
        }

        return "Navegador";
    }

    private String operatingSystem(
            String userAgent
    ) {
        String ua = userAgent.toLowerCase(Locale.ROOT);

        if (ua.contains("windows")) {
            return "Windows";
        }
        if (ua.contains("android")) {
            return "Android";
        }
        if (ua.contains("iphone") || ua.contains("ipad")) {
            return "iOS";
        }
        if (ua.contains("mac os")) {
            return "macOS";
        }
        if (ua.contains("linux")) {
            return "Linux";
        }

        return "Sistema operativo";
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
