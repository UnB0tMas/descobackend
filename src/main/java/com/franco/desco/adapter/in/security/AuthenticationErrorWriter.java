package com.franco.desco.adapter.in.security;

import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;

@Component
public class AuthenticationErrorWriter {

    private final JsonMapper jsonMapper;

    public AuthenticationErrorWriter(
            JsonMapper jsonMapper
    ) {
        this.jsonMapper = jsonMapper;
    }

    public void unauthorized(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        write(
                request,
                response,
                401,
                "NO_AUTENTICADO",
                "Su sesión no es válida. Inicie sesión nuevamente."
        );
    }

    public void forbidden(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        write(
                request,
                response,
                403,
                "ACCESO_NO_AUTORIZADO",
                "No cuenta con autorización para realizar esta acción."
        );
    }

    public void serviceUnavailable(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        write(
                request,
                response,
                503,
                "SERVICIO_NO_DISPONIBLE",
                "El servicio no está disponible temporalmente. Intente nuevamente."
        );
    }

    private void write(
            HttpServletRequest request,
            HttpServletResponse response,
            int status,
            String code,
            String message
    ) throws IOException {
        response.setStatus(status);
        response.setContentType(
                MediaType.APPLICATION_JSON_VALUE
        );
        response.setCharacterEncoding("UTF-8");

        UUID correlationId =
                CorrelationIdFilter.correlationId(
                        request
                );

        ApiResponse<Void> body =
                new ApiResponse<>(
                        false,
                        code,
                        message,
                        null,
                        correlationId,
                        Instant.now()
                );

        jsonMapper.writeValue(
                response.getOutputStream(),
                body
        );
    }
}
