package com.franco.desco.adapter.in.web.common;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;
import java.util.function.Function;

@Component
public class ApiResponseFactory {

    public <S, T> ResponseEntity<ApiResponse<T>> from(
            AppResult<S> result,
            HttpServletRequest request,
            Function<S, T> mapper
    ) {
        T data = result.datos() == null
                ? null
                : mapper.apply(result.datos());

        UUID correlationId =
                CorrelationIdFilter.correlationId(
                        request
                );

        ApiResponse<T> body =
                new ApiResponse<>(
                        result.exitoso(),
                        result.codigo(),
                        result.mensaje(),
                        data,
                        correlationId,
                        Instant.now()
                );

        return ResponseEntity
                .status(toHttpStatus(result.estado()))
                .body(body);
    }

    public <T> ResponseEntity<ApiResponse<T>> from(
            AppResult<T> result,
            HttpServletRequest request
    ) {
        return from(
                result,
                request,
                Function.identity()
        );
    }

    private HttpStatus toHttpStatus(
            AppStatus status
    ) {
        return switch (status) {
            case OK -> HttpStatus.OK;
            case CREATED -> HttpStatus.CREATED;
            case BAD_REQUEST -> HttpStatus.BAD_REQUEST;
            case UNAUTHORIZED -> HttpStatus.UNAUTHORIZED;
            case FORBIDDEN -> HttpStatus.FORBIDDEN;
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case TOO_MANY_REQUESTS ->
                    HttpStatus.TOO_MANY_REQUESTS;
            case SERVICE_UNAVAILABLE ->
                    HttpStatus.SERVICE_UNAVAILABLE;
            case INTERNAL_ERROR ->
                    HttpStatus.INTERNAL_SERVER_ERROR;
        };
    }
}
