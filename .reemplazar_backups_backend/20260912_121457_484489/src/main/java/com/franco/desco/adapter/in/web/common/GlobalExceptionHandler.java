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

    @ExceptionHandler(
            MethodArgumentNotValidException.class
    )
    public ResponseEntity<ApiResponse<Void>> validation(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        String message = exception
                .getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error ->
                        error.getDefaultMessage()
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

    @ExceptionHandler(
            ConstraintViolationException.class
    )
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

    @ExceptionHandler(
            IdempotencyKeyException.class
    )
    public ResponseEntity<ApiResponse<Void>> idempotency(
            IdempotencyKeyException exception,
            HttpServletRequest request
    ) {
        return error(
                HttpStatus.BAD_REQUEST,
                "CLAVE_IDEMPOTENCIA_NO_VALIDA",
                exception.getMessage(),
                request
        );
    }

    @ExceptionHandler(PaExecutionException.class)
    public ResponseEntity<ApiResponse<Void>> database(
            PaExecutionException exception,
            HttpServletRequest request
    ) {
        log.error(
                "Fallo de infraestructura SQL. correlationId={}",
                CorrelationIdFilter.correlationId(request),
                exception
        );

        return error(
                HttpStatus.SERVICE_UNAVAILABLE,
                "SERVICIO_NO_DISPONIBLE",
                "El servicio no está disponible temporalmente. Intente nuevamente.",
                request
        );
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> generic(
            Exception exception,
            HttpServletRequest request
    ) {
        log.error(
                "Error no controlado. correlationId={}",
                CorrelationIdFilter.correlationId(request),
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
                CorrelationIdFilter.correlationId(
                        request
                );

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
}
