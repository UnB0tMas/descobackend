package com.franco.desco.adapter.in.web.common;

import com.franco.desco.adapter.in.web.common.idempotency.IdempotencyKeyException;
import com.franco.desco.adapter.out.sqlserver.shared.PaExecutionException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.http.converter.HttpMessageNotWritableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({HttpMessageNotReadableException.class, MissingServletRequestParameterException.class,
            MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ApiResponse<Void>> unreadable(Exception exception, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "SOLICITUD_NO_VALIDA",
                "Revise los campos obligatorios y el formato de la información enviada.", request);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> accessDenied(AccessDeniedException exception, HttpServletRequest request) {
        return error(HttpStatus.FORBIDDEN, "NO_AUTORIZADO", "No tiene permiso para realizar esta operación en la UOT seleccionada.", request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> validation(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        // El detalle de validación se conserva en el backend para diagnóstico por correlación.
        // No registrar el cuerpo ni valores rechazados: pueden contener datos personales.
        log.warn("Validación de solicitud fallida. correlationId={} metodo={} endpoint={} campos={}",
                CorrelationIdFilter.correlationId(request), request.getMethod(), request.getRequestURI(),
                exception.getBindingResult().getAllErrors().stream()
                        .map(issue -> issue instanceof FieldError field
                                ? field.getField() + " [" + field.getCode() + "]: " + field.getDefaultMessage()
                                : issue.getObjectName() + " [" + issue.getCode() + "]: " + issue.getDefaultMessage())
                        .toList());

        String message = exception
                .getBindingResult()
                .getAllErrors()
                .stream()
                .map(error -> error instanceof FieldError field
                        ? "Revise " + field.getField() + ": " + field.getDefaultMessage()
                        : error.getDefaultMessage())
                .filter(this::hasText)
                .findFirst()
                .map(value -> safePublicMessage(
                        value,
                        "Revise la información ingresada."
                ))
                .orElse("Revise la información ingresada.");

        return error(
                HttpStatus.BAD_REQUEST,
                "SOLICITUD_NO_VALIDA",
                request.getRequestURI().startsWith("/api/v1/apappss/plantas")
                        ? "Revise los datos ingresados de la planta e inténtelo nuevamente."
                        : message,
                request
        );
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Void>> constraint(
            ConstraintViolationException exception,
            HttpServletRequest request
    ) {
        log.warn("Validación de parámetros fallida. correlationId={} metodo={} endpoint={} restricciones={}",
                CorrelationIdFilter.correlationId(request), request.getMethod(), request.getRequestURI(),
                exception.getConstraintViolations().stream()
                        .map(issue -> issue.getPropertyPath() + ": " + issue.getMessage())
                        .toList());

        String message = exception
                .getConstraintViolations()
                .stream()
                .map(violation -> violation.getMessage())
                .filter(this::hasText)
                .findFirst()
                .map(value -> safePublicMessage(
                        value,
                        "Revise la información ingresada."
                ))
                .orElse("Revise la información ingresada.");

        return error(
                HttpStatus.BAD_REQUEST,
                "SOLICITUD_NO_VALIDA",
                request.getRequestURI().startsWith("/api/v1/apappss/plantas")
                        ? "Revise los datos ingresados de la planta e inténtelo nuevamente."
                        : message,
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

    @ExceptionHandler(MissingServletRequestPartException.class)
    public ResponseEntity<ApiResponse<Void>> missingMultipartPart(
            MissingServletRequestPartException exception,
            HttpServletRequest request
    ) {
        return error(
                HttpStatus.BAD_REQUEST,
                "ARCHIVO_REQUERIDO",
                "Seleccione un archivo para cargar.",
                request
        );
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> maxUploadSize(
            MaxUploadSizeExceededException exception,
            HttpServletRequest request
    ) {
        return error(
                HttpStatus.BAD_REQUEST,
                "ARCHIVO_DEMASIADO_GRANDE",
                "El archivo supera el tamaño permitido.",
                request
        );
    }

    @ExceptionHandler(MultipartException.class)
    public ResponseEntity<ApiResponse<Void>> multipart(
            MultipartException exception,
            HttpServletRequest request
    ) {
        log.warn(
                "Solicitud multipart inválida. correlationId={} endpoint={}",
                CorrelationIdFilter.correlationId(request),
                request.getRequestURI()
        );

        return error(
                HttpStatus.BAD_REQUEST,
                "ARCHIVO_INVALIDO",
                "No se pudo procesar el archivo enviado.",
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
                safePublicMessage(
                        exception.getMessage(),
                        "Revise la información ingresada."
                ),
                request
        );
    }

    @ExceptionHandler(HttpMessageNotWritableException.class)
    public ResponseEntity<ApiResponse<Void>> responseNotWritable(
            HttpMessageNotWritableException exception,
            HttpServletRequest request
    ) {
        Throwable cause = exception;
        while (cause != null) {
            // Tomcat identifica una conexión cerrada por el cliente: no es un fallo de JSON ni SQL.
            if ("org.apache.catalina.connector.ClientAbortException".equals(cause.getClass().getName())) {
                log.debug(
                        "El cliente cerró la conexión durante la respuesta. correlationId={} endpoint={}",
                        CorrelationIdFilter.correlationId(request),
                        request.getRequestURI()
                );
                // La respuesta ya no se puede escribir: no intentar devolver otro JSON ni un 500.
                return null;
            }
            cause = cause.getCause();
        }
        // Los errores reales de serialización mantienen el tratamiento y la trazabilidad existentes.
        return generic(exception, request);
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
        if (!hasText(value)) {
            return fallback;
        }

        String message = value.trim();
        String lower = message.toLowerCase(Locale.ROOT);

        if (lower.contains("exception")
                || lower.contains("sqlstate")
                || lower.contains("jdbc")
                || lower.contains("stack trace")
                || lower.contains("stored procedure")
                || lower.contains("constraint ")
                || lower.contains("duplicate key")
                || lower.contains("foreign key")
                || lower.contains("nvarchar")
                || lower.contains("varchar")) {
            return fallback;
        }

        return message.length() <= 300
                ? message
                : fallback;
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
