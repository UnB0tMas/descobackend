package com.franco.desco.adapter.in.security;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecutionException;
import com.franco.desco.application.auth.port.out.SessionValidationPort;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.port.out.RequestHashPort;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class SessionValidationFilter
        extends OncePerRequestFilter {

    private static final Logger log =
            LoggerFactory.getLogger(
                    SessionValidationFilter.class
            );

    private final SessionValidationPort sessionValidationPort;
    private final RequestHashPort requestHashPort;
    private final AuthenticationErrorWriter errorWriter;
    private final JwtSessionIdentityResolver identityResolver;

    public SessionValidationFilter(
            SessionValidationPort sessionValidationPort,
            RequestHashPort requestHashPort,
            AuthenticationErrorWriter errorWriter,
            JwtSessionIdentityResolver identityResolver
    ) {
        this.sessionValidationPort =
                sessionValidationPort;
        this.requestHashPort =
                requestHashPort;
        this.errorWriter =
                errorWriter;
        this.identityResolver =
                identityResolver;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        if (!(SecurityContextHolder
                .getContext()
                .getAuthentication()
                instanceof JwtAuthenticationToken authentication)
                || !authentication.isAuthenticated()) {

            filterChain.doFilter(
                    request,
                    response
            );
            return;
        }

        SessionIdentity identity;

        try {
            identity =
                    identityResolver.resolve(
                            authentication
                    );
        } catch (IllegalArgumentException exception) {
            /*
             * No se registra el JWT ni ninguno de sus secretos.
             * El mensaje permite diferenciar un token criptográficamente
             * aceptado pero con claims de identidad inválidos.
             */
            log.warn(
                    "JWT autenticado con identidad de sesión inválida en {}: {}",
                    request.getRequestURI(),
                    exception.getMessage()
            );

            rejectUnauthorized(
                    request,
                    response
            );
            return;
        }

        try {
            String jtiHash =
                    requestHashPort.sha256Hex(
                            identity.jti()
                    );

            boolean valid =
                    sessionValidationPort.isValid(
                            identity,
                            jtiHash,
                            request.getRemoteAddr()
                    );

            if (!valid) {
                log.warn(
                        "Sesión rechazada para usuarioId={} sesionPublicaId={} endpoint={}",
                        identity.usuarioId(),
                        identity.sesionPublicaId(),
                        request.getRequestURI()
                );

                rejectUnauthorized(
                        request,
                        response
                );
                return;
            }

            filterChain.doFilter(
                    request,
                    response
            );

        } catch (PaExecutionException exception) {
            SecurityContextHolder.clearContext();

            log.error(
                    "No fue posible validar la sesión contra persistencia en endpoint={}",
                    request.getRequestURI(),
                    exception
            );

            errorWriter.serviceUnavailable(
                    request,
                    response
            );

        } catch (RuntimeException exception) {
            /*
             * Nunca incluir access token, refresh token, JTI ni hashes
             * sensibles en el log.
             */
            log.error(
                    "Error inesperado durante la validación de sesión en endpoint={}",
                    request.getRequestURI(),
                    exception
            );

            rejectUnauthorized(
                    request,
                    response
            );
        }
    }

    private void rejectUnauthorized(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        SecurityContextHolder.clearContext();

        errorWriter.unauthorized(
                request,
                response
        );
    }
}
