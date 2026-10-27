package com.franco.desco.adapter.in.web.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class CorrelationIdFilter
        extends OncePerRequestFilter {

    public static final String HEADER =
            "X-Correlation-Id";

    private static final String ATTRIBUTE =
            CorrelationIdFilter.class.getName()
                    + ".CORRELATION_ID";

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        UUID correlationId =
                parseOrGenerate(
                        request.getHeader(HEADER)
                );

        request.setAttribute(
                ATTRIBUTE,
                correlationId
        );

        response.setHeader(
                HEADER,
                correlationId.toString()
        );

        boolean uploadTrace = isLocalDocumentUpload(request);
        long startedNanos = System.nanoTime();

        if (uploadTrace) {
            log.info(
                    "[DESCO-UPLOAD-TRACE][BACKEND][FILTER][IN] "
                            + "correlationId={} method={} uri={} query={} "
                            + "contentType={} contentLength={} "
                            + "idempotencyPresent={} authorizationPresent={} "
                            + "transferEncoding={}",
                    correlationId,
                    request.getMethod(),
                    request.getRequestURI(),
                    request.getQueryString(),
                    request.getContentType(),
                    request.getContentLengthLong(),
                    hasHeader(request, "X-Idempotency-Key"),
                    hasHeader(request, "Authorization"),
                    request.getHeader("Transfer-Encoding")
            );
        }

        try {
            filterChain.doFilter(
                    request,
                    response
            );
        } catch (RuntimeException | ServletException | IOException exception) {
            if (uploadTrace) {
                log.error(
                        "[DESCO-UPLOAD-TRACE][BACKEND][FILTER][THROW] "
                                + "correlationId={} status={} exception={} message={}",
                        correlationId,
                        response.getStatus(),
                        exception.getClass().getName(),
                        safeLogMessage(exception.getMessage()),
                        exception
                );
            }
            throw exception;
        } finally {
            if (uploadTrace) {
                long durationMs =
                        (System.nanoTime() - startedNanos) / 1_000_000L;

                log.info(
                        "[DESCO-UPLOAD-TRACE][BACKEND][FILTER][OUT] "
                                + "correlationId={} status={} durationMs={} "
                                + "responseContentType={}",
                        correlationId,
                        response.getStatus(),
                        durationMs,
                        response.getContentType()
                );
            }
        }
    }

    private boolean isLocalDocumentUpload(
            HttpServletRequest request
    ) {
        return "POST".equalsIgnoreCase(request.getMethod())
                && "/api/v1/documentos/local".equals(
                        request.getRequestURI()
                );
    }

    private boolean hasHeader(
            HttpServletRequest request,
            String name
    ) {
        String value = request.getHeader(name);
        return value != null && !value.isBlank();
    }

    private String safeLogMessage(String value) {
        if (value == null || value.isBlank()) {
            return "(sin mensaje)";
        }

        return value
                .replace('\r', ' ')
                .replace('\n', ' ')
                .trim();
    }

    public static UUID correlationId(
            HttpServletRequest request
    ) {
        Object value =
                request.getAttribute(ATTRIBUTE);

        if (value instanceof UUID uuid) {
            return uuid;
        }

        return UUID.randomUUID();
    }

    private UUID parseOrGenerate(String value) {
        try {
            return value == null || value.isBlank()
                    ? UUID.randomUUID()
                    : UUID.fromString(value);
        } catch (IllegalArgumentException exception) {
            return UUID.randomUUID();
        }
    }
}
