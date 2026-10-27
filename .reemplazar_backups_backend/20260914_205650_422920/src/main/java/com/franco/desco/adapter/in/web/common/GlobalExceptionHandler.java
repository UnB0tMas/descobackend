package com.franco.desco.adapter.in.web.common;

import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyException;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecutionException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.UUID;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> validation(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        String message = exception
                .getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .filter(value ->
                        value != null
                                && !value.isBlank()
                )
                .orElse(
                        "Revise la información ingresada."
                );

        return error(
                HttpStatus.BAD_REQUEST,
                "SOLICITUD_NO_VALIDA",
                message,
                request
        );
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> constraint(
            ConstraintViolationException exception,
            HttpServletRequest request
    ) {
        return error(
                HttpStatus.BAD_REQUEST,
                "SOLICITUD_NO_VALIDA",
                "Revise la información ingresada.",
                request
        );
    }

    @ExceptionHandler(IdempotencyKeyException.class)
    public ResponseEntity<ApiResponse<Void>> idempotency(
            IdempotencyKeyException exception,
            HttpServletRequest request
    ) {
        return error(
                HttpStatus.BAD_REQUEST,
                "CLAVE_IDEMPOTENCIA_NO_VALIDA",
                safePublicMessage(
                        exception.getMessage(),
                        "Envíe una clave válida para procesar esta operación."
                ),
                request
        );
    }

    @ExceptionHandler(PaExecutionException.class)
    public ResponseEntity<ApiResponse<Void>> database(
            PaExecutionException exception,
            HttpServletRequest request
    ) {
        UUID correlationId =
                CorrelationIdFilter.correlationId(request);

        log.error(
                "Fallo SQL controlado. procedure={} dbCode={} sqlState={} correlationId={}",
                exception.procedure(),
                exception.databaseErrorCode(),
                exception.sqlState(),
                correlationId,
                exception
        );

        if (exception.duplicateKey()) {
            return error(
                    HttpStatus.CONFLICT,
                    "REGISTRO_DUPLICADO",
                    "La información ya se encuentra registrada.",
                    request
            );
        }

        if (exception.retryable()) {
            return error(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "OPERACION_REINTENTABLE",
                    "No se pudo completar la acción en este momento. Intente nuevamente.",
                    request
            );
        }

        return error(
                HttpStatus.SERVICE_UNAVAILABLE,
                "SERVICIO_NO_DISPONIBLE",
                "El servicio no está disponible temporalmente. Intente nuevamente.",
                request
        );
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> illegalArgument(
            IllegalArgumentException exception,
            HttpServletRequest request
    ) {
        log.warn(
                "Solicitud rechazada. correlationId={} endpoint={}",
                CorrelationIdFilter.correlationId(request),
                request.getRequestURI()
        );

        return error(
                HttpStatus.BAD_REQUEST,
                "SOLICITUD_NO_VALIDA",
                "Revise la información ingresada.",
                request
        );
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> generic(
            Exception exception,
            HttpServletRequest request
    ) {
        log.error(
                "Error no controlado. correlationId={} endpoint={}",
                CorrelationIdFilter.correlationId(request),
                request.getRequestURI(),
                exception
        );

        return error(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "NO_PROCESADO",
                "No se pudo procesar la solicitud. Intente nuevamente.",
                request
        );
    }

    private ResponseEntity<ApiResponse<Void>> error(
            HttpStatus status,
            String code,
            String message,
            HttpServletRequest request
    ) {
        UUID correlationId =
                CorrelationIdFilter.correlationId(request);

        return ResponseEntity
                .status(status)
                .body(
                        new ApiResponse<>(
                                false,
                                code,
                                message,
                                null,
                                correlationId,
                                Instant.now()
                        )
                );
    }

    private String safePublicMessage(
            String value,
            String fallback
    ) {
        if (value == null
                || value.isBlank()) {
            return fallback;
        }

        String lower =
                value.toLowerCase(
                        java.util.Locale.ROOT
                );

        if (lower.contains("exception")
                || lower.contains("sql")
                || lower.contains("jdbc")
                || lower.contains("stack")
                || lower.contains("constraint")) {
            return fallback;
        }

        return value.trim();
    }
}
