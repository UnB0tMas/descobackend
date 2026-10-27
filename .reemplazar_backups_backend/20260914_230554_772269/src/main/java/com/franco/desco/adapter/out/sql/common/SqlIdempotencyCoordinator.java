package com.franco.desco.adapter.out.sql.common;

import com.franco.desco.application.shared.PersistenceResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;

@Component
public class SqlIdempotencyCoordinator {

    private static final Logger log =
            LoggerFactory.getLogger(SqlIdempotencyCoordinator.class);

    private final JdbcTemplate jdbc;
    private final TransactionTemplate transaction;

    public SqlIdempotencyCoordinator(
            JdbcTemplate jdbc,
            PlatformTransactionManager transactionManager
    ) {
        this.jdbc = jdbc;
        this.transaction = new TransactionTemplate(transactionManager);
    }

    public PersistenceResult<Long> executeLong(
            Long userId,
            UUID key,
            String scope,
            String entitySchema,
            String entityName,
            Supplier<PersistenceResult<Long>> operation
    ) {
        if (userId == null) {
            return PersistenceResult.error(
                    "USUARIO_NO_DISPONIBLE",
                    "No se pudo identificar al usuario de la operación.",
                    401
            );
        }

        if (key == null) {
            return PersistenceResult.error(
                    "CLAVE_IDEMPOTENCIA_NO_VALIDA",
                    "La clave de solicitud es obligatoria.",
                    400
            );
        }

        String normalizedScope = normalizeScope(scope);
        if (normalizedScope == null) {
            return PersistenceResult.error(
                    "AMBITO_IDEMPOTENCIA_NO_VALIDO",
                    "No se pudo identificar la operación solicitada.",
                    400
            );
        }

        String keyText = key.toString();

        try {
            PersistenceResult<Long> result = transaction.execute(status -> {
                acquireLock(lockResource(userId, normalizedScope, keyText));

                Existing existing = existing(
                        userId,
                        normalizedScope,
                        keyText
                );

                if (existing != null) {
                    if ("COMPLETADA".equals(existing.status())
                            && existing.resultId() != null) {
                        try {
                            return PersistenceResult.ok(
                                    existing.code(),
                                    existing.message() == null
                                            ? "La operación ya fue procesada correctamente."
                                            : existing.message(),
                                    200,
                                    Long.valueOf(existing.resultId())
                            );
                        } catch (NumberFormatException ignored) {
                            return PersistenceResult.error(
                                    "RESULTADO_IDEMPOTENCIA_NO_DISPONIBLE",
                                    "No se pudo recuperar el resultado de la operación anterior.",
                                    409
                            );
                        }
                    }

                    if ("FALLIDA".equals(existing.status())) {
                        return PersistenceResult.error(
                                existing.code(),
                                existing.message() == null
                                        ? "La solicitud anterior no se completó. Envíe una nueva solicitud."
                                        : existing.message(),
                                409
                        );
                    }

                    return PersistenceResult.error(
                            "OPERACION_EN_PROCESO",
                            "La solicitud todavía se está procesando.",
                            409
                    );
                }

                insertOperation(userId, normalizedScope, keyText);

                PersistenceResult<Long> operationResult = operation.get();

                if (operationResult == null
                        || !operationResult.exitoso()
                        || operationResult.datos() == null) {
                    status.setRollbackOnly();
                    return operationResult == null
                            ? PersistenceResult.error(
                                    "OPERACION_NO_PROCESADA",
                                    "No se pudo completar la operación.",
                                    400
                            )
                            : operationResult;
                }

                completeOperation(
                        userId,
                        normalizedScope,
                        keyText,
                        entitySchema,
                        entityName,
                        String.valueOf(operationResult.datos()),
                        operationResult.codigo(),
                        operationResult.mensaje()
                );

                return operationResult;
            });

            return result == null
                    ? PersistenceResult.error(
                            "OPERACION_NO_PROCESADA",
                            "No se pudo completar la operación en este momento.",
                            503
                    )
                    : result;

        } catch (DataAccessException | IllegalStateException exception) {
            log.error(
                    "Fallo en idempotencia SQL. userId={} scope={} key={} error={}",
                    userId,
                    normalizedScope,
                    keyText,
                    exception.getClass().getSimpleName(),
                    exception
            );

            return PersistenceResult.error(
                    "IDEMPOTENCIA_NO_DISPONIBLE",
                    "No se pudo completar la operación en este momento. Intente nuevamente.",
                    503
            );
        }
    }

    public PersistenceResult<Void> executeVoid(
            Long userId,
            UUID key,
            String scope,
            String entitySchema,
            String entityName,
            Supplier<PersistenceResult<Void>> operation
    ) {
        if (userId == null) {
            return PersistenceResult.error(
                    "USUARIO_NO_DISPONIBLE",
                    "No se pudo identificar al usuario de la operación.",
                    401
            );
        }

        if (key == null) {
            return PersistenceResult.error(
                    "CLAVE_IDEMPOTENCIA_NO_VALIDA",
                    "La clave de solicitud es obligatoria.",
                    400
            );
        }

        String normalizedScope = normalizeScope(scope);
        if (normalizedScope == null) {
            return PersistenceResult.error(
                    "AMBITO_IDEMPOTENCIA_NO_VALIDO",
                    "No se pudo identificar la operación solicitada.",
                    400
            );
        }

        String keyText = key.toString();

        try {
            PersistenceResult<Void> result = transaction.execute(status -> {
                acquireLock(lockResource(userId, normalizedScope, keyText));

                Existing existing = existing(
                        userId,
                        normalizedScope,
                        keyText
                );

                if (existing != null) {
                    if ("COMPLETADA".equals(existing.status())) {
                        return PersistenceResult.ok(
                                existing.code(),
                                existing.message() == null
                                        ? "La operación ya fue procesada correctamente."
                                        : existing.message(),
                                200,
                                null
                        );
                    }

                    if ("FALLIDA".equals(existing.status())) {
                        return PersistenceResult.error(
                                existing.code(),
                                existing.message() == null
                                        ? "La solicitud anterior no se completó. Envíe una nueva solicitud."
                                        : existing.message(),
                                409
                        );
                    }

                    return PersistenceResult.error(
                            "OPERACION_EN_PROCESO",
                            "La solicitud todavía se está procesando.",
                            409
                    );
                }

                insertOperation(userId, normalizedScope, keyText);

                PersistenceResult<Void> operationResult = operation.get();

                if (operationResult == null
                        || !operationResult.exitoso()) {
                    status.setRollbackOnly();
                    return operationResult == null
                            ? PersistenceResult.error(
                                    "OPERACION_NO_PROCESADA",
                                    "No se pudo completar la operación.",
                                    400
                            )
                            : operationResult;
                }

                completeOperation(
                        userId,
                        normalizedScope,
                        keyText,
                        entitySchema,
                        entityName,
                        null,
                        operationResult.codigo(),
                        operationResult.mensaje()
                );

                return operationResult;
            });

            return result == null
                    ? PersistenceResult.error(
                            "OPERACION_NO_PROCESADA",
                            "No se pudo completar la operación en este momento.",
                            503
                    )
                    : result;

        } catch (DataAccessException | IllegalStateException exception) {
            log.error(
                    "Fallo en idempotencia SQL. userId={} scope={} key={} error={}",
                    userId,
                    normalizedScope,
                    keyText,
                    exception.getClass().getSimpleName(),
                    exception
            );

            return PersistenceResult.error(
                    "IDEMPOTENCIA_NO_DISPONIBLE",
                    "No se pudo completar la operación en este momento. Intente nuevamente.",
                    503
            );
        }
    }

    private void insertOperation(
            Long userId,
            String scope,
            String keyText
    ) {
        jdbc.update(
                """
                INSERT INTO auditoria.OperacionIdempotente
                (
                    usuario_id,
                    clave_idempotencia,
                    ambito,
                    fecha_inicio,
                    estado_operacion,
                    fecha_expiracion,
                    estado
                )
                VALUES
                (
                    ?,
                    CONVERT(uniqueidentifier, ?),
                    ?,
                    SYSUTCDATETIME(),
                    'EN_PROCESO',
                    DATEADD(day, 7, SYSUTCDATETIME()),
                    1
                )
                """,
                userId,
                keyText,
                scope
        );
    }

    private void completeOperation(
            Long userId,
            String scope,
            String keyText,
            String entitySchema,
            String entityName,
            String resultId,
            String resultCode,
            String resultMessage
    ) {
        jdbc.update(
                """
                UPDATE auditoria.OperacionIdempotente
                SET
                    estado_operacion = 'COMPLETADA',
                    fecha_fin = SYSUTCDATETIME(),
                    esquema_entidad = ?,
                    nombre_entidad = ?,
                    identificador_resultado = ?,
                    codigo_resultado = ?,
                    mensaje_resultado = ?
                WHERE usuario_id = ?
                  AND ambito = ?
                  AND clave_idempotencia = CONVERT(uniqueidentifier, ?)
                  AND estado = 1
                """,
                entitySchema,
                entityName,
                resultId,
                resultCode,
                resultMessage,
                userId,
                scope,
                keyText
        );
    }

    private Existing existing(
            Long userId,
            String scope,
            String keyText
    ) {
        List<Existing> values = jdbc.query(
                """
                SELECT TOP (1)
                    estado_operacion,
                    identificador_resultado,
                    codigo_resultado,
                    mensaje_resultado
                FROM auditoria.OperacionIdempotente
                WHERE usuario_id = ?
                  AND ambito = ?
                  AND clave_idempotencia = CONVERT(uniqueidentifier, ?)
                  AND estado = 1
                ORDER BY operacion_idempotente_id DESC
                """,
                (resultSet, rowNumber) -> new Existing(
                        resultSet.getString("estado_operacion"),
                        resultSet.getString("identificador_resultado"),
                        resultSet.getString("codigo_resultado"),
                        resultSet.getString("mensaje_resultado")
                ),
                userId,
                scope,
                keyText
        );

        return values.isEmpty()
                ? null
                : values.getFirst();
    }

    private void acquireLock(String resource) {
        Integer result = jdbc.queryForObject(
                """
                DECLARE @resultado INT;
                EXEC @resultado = sys.sp_getapplock
                    @Resource = ?,
                    @LockMode = 'Exclusive',
                    @LockOwner = 'Transaction',
                    @LockTimeout = 10000;
                SELECT @resultado;
                """,
                Integer.class,
                resource
        );

        if (result == null || result < 0) {
            throw new IllegalStateException(
                    "No se pudo reservar la operación idempotente."
            );
        }
    }

    private String lockResource(
            Long userId,
            String scope,
            String keyText
    ) {
        return "DESCO:IDEMPOTENCY:"
                + userId
                + ':'
                + scope
                + ':'
                + keyText;
    }

    private String normalizeScope(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized = value.trim().toUpperCase(java.util.Locale.ROOT);
        return normalized.length() <= 100
                ? normalized
                : normalized.substring(0, 100);
    }

    private record Existing(
            String status,
            String resultId,
            String code,
            String message
    ) {
    }
}
