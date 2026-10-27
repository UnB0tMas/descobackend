package com.franco.desco.adapter.in.web.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

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

        filterChain.doFilter(
                request,
                response
        );
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
