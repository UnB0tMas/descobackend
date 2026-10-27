package com.franco.desco.adapter.out.sql.common;

import com.franco.desco.application.shared.PersistenceResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import javax.sql.DataSource;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import java.util.function.Function;
import java.util.function.Supplier;

/**
 * Coordinador común de idempotencia SQL Server.
 *
 * Regla importante para SQL Server:
 * sp_getapplock con LockOwner='Transaction' exige que exista una transacción
 * física en SQL Server. Spring puede tener una transacción lógica/JDBC abierta
 * antes de que @@TRANCOUNT sea mayor que cero; por eso se materializa la
 * transacción de servidor antes de solicitar el application lock.
 */
@Component
public final class SqlIdempotencyCoordinator {

    private static final Logger log =
            LoggerFactory.getLogger(SqlIdempotencyCoordinator.class);

    private static final String TECHNICAL_CODE =
            "IDEMPOTENCIA_NO_DISPONIBLE";

    private static final String TECHNICAL_MESSAGE =
            "No se pudo completar la operación en este momento. Intente nuevamente.";

    private static final String LOCK_SQL = """
            DECLARE @resultado INT;
            EXEC @resultado = sys.sp_getapplock
                 @Resource = ?,
                 @LockMode = 'Exclusive',
                 @LockOwner = 'Transaction',
                 @LockTimeout = 10000,
                 @DbPrincipal = 'public';
            SELECT @resultado;
            """;

    private static final String RESERVE_SQL = """
            DECLARE
                @id BIGINT,
                @repetida BIT,
                @estado VARCHAR(20),
                @identificador NVARCHAR(200),
                @codigoResultado VARCHAR(40),
                @resultado BIT,
                @mensaje NVARCHAR(300),
                @codigoRespuesta VARCHAR(60),
                @httpRespuesta SMALLINT;

            EXEC [auditoria].[PA_OperacionIdempotente_Ins_Iniciar]
                 @nUsuarioId = ?,
                 @gClaveIdempotencia = ?,
                 @cAmbito = ?,
                 @cRequestHashHex = NULL,
                 @nMinutosVigencia = 1440,
                 @nOperacionIdempotenteId = @id OUTPUT,
                 @bEsRepetida = @repetida OUTPUT,
                 @cEstadoOperacion = @estado OUTPUT,
                 @cIdentificadorResultado = @identificador OUTPUT,
                 @cCodigoResultado = @codigoResultado OUTPUT,
                 @bResultado = @resultado OUTPUT,
                 @cMensaje = @mensaje OUTPUT,
                 @cCodigoRespuesta = @codigoRespuesta OUTPUT,
                 @nHttpRespuesta = @httpRespuesta OUTPUT;

            SELECT
                @id AS operacionId,
                @repetida AS repetida,
                @estado AS estadoOperacion,
                @identificador AS identificadorResultado,
                @codigoResultado AS codigoResultado,
                @resultado AS resultado,
                @mensaje AS mensaje,
                @codigoRespuesta AS codigoRespuesta,
                @httpRespuesta AS httpRespuesta,
                O.mensaje_resultado AS mensajeGuardado
            FROM (VALUES (1)) V(x)
            LEFT JOIN [auditoria].[OperacionIdempotente] O
              ON O.operacion_idempotente_id = @id;
            """;

    private static final String COMPLETE_SQL = """
            DECLARE
                @resultado BIT,
                @mensaje NVARCHAR(300),
                @codigoRespuesta VARCHAR(60),
                @httpRespuesta SMALLINT;

            EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar]
                 @nOperacionIdempotenteId = ?,
                 @cEstadoOperacion = 'COMPLETADA',
                 @cEsquemaEntidad = ?,
                 @cNombreEntidad = ?,
                 @cIdentificadorResultado = ?,
                 @cCodigoResultado = ?,
                 @bResultado = @resultado OUTPUT,
                 @cMensaje = @mensaje OUTPUT,
                 @cCodigoRespuesta = @codigoRespuesta OUTPUT,
                 @nHttpRespuesta = @httpRespuesta OUTPUT;

            SELECT
                @resultado AS resultado,
                @mensaje AS mensaje;
            """;

    private static final String FAIL_SQL = """
            DECLARE
                @resultado BIT,
                @mensaje NVARCHAR(300),
                @codigoRespuesta VARCHAR(60),
                @httpRespuesta SMALLINT;

            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = ?,
                 @cMensajeResultado = ?,
                 @bResultado = @resultado OUTPUT,
                 @cMensaje = @mensaje OUTPUT,
                 @cCodigoRespuesta = @codigoRespuesta OUTPUT,
                 @nHttpRespuesta = @httpRespuesta OUTPUT;

            SELECT
                @resultado AS resultado,
                @mensaje AS mensaje;
            """;

    private final JdbcTemplate jdbc;
    private final TransactionTemplate transaction;

    public SqlIdempotencyCoordinator(
            DataSource dataSource,
            PlatformTransactionManager transactionManager
    ) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.transaction = new TransactionTemplate(transactionManager);
    }

    public PersistenceResult<Long> executeLong(
            Long userId,
            UUID idempotencyKey,
            String scope,
            String entitySchema,
            String entityName,
            Supplier<PersistenceResult<Long>> operation
    ) {
        return execute(
                userId,
                idempotencyKey,
                scope,
                entitySchema,
                entityName,
                operation,
                this::parseLongReplay
        );
    }

    public PersistenceResult<Void> executeVoid(
            Long userId,
            UUID idempotencyKey,
            String scope,
            String entitySchema,
            String entityName,
            Supplier<PersistenceResult<Void>> operation
    ) {
        return execute(
                userId,
                idempotencyKey,
                scope,
                entitySchema,
                entityName,
                operation,
                ignored -> null
        );
    }

    private <T> PersistenceResult<T> execute(
            Long userId,
            UUID idempotencyKey,
            String scope,
            String entitySchema,
            String entityName,
            Supplier<PersistenceResult<T>> operation,
            Function<String, T> replayValue
    ) {
        if (userId == null
                || idempotencyKey == null
                || !hasText(scope)
                || operation == null) {
            return PersistenceResult.error(
                    "CLAVE_IDEMPOTENCIA_NO_VALIDA",
                    "La solicitud no contiene una clave de idempotencia válida.",
                    400
            );
        }

        String normalizedScope = scope.trim();

        try {
            PersistenceResult<T> result = transaction.execute(status -> {
                /*
                 * CRÍTICO: DataSourceTransactionManager puede haber desactivado
                 * autoCommit sin que SQL Server haya materializado todavía una
                 * transacción (@@TRANCOUNT = 0). LockOwner='Transaction' falla
                 * en ese estado. Se fuerza BEGIN TRANSACTION una sola vez y el
                 * commit/rollback sigue siendo responsabilidad de Spring.
                 */
                ensurePhysicalSqlServerTransaction();

                acquireLock(
                        userId,
                        normalizedScope,
                        idempotencyKey
                );

                Reservation reservation = reserve(
                        userId,
                        idempotencyKey,
                        normalizedScope
                );

                if (!reservation.accepted()) {
                    return rejectedReservation(reservation);
                }

                if (reservation.repeated()) {
                    return replay(
                            reservation,
                            replayValue
                    );
                }

                PersistenceResult<T> operationResult = operation.get();
                if (operationResult == null) {
                    throw new IllegalStateException(
                            "La operación idempotente no devolvió resultado."
                    );
                }

                if (!operationResult.exitoso()) {
                    rememberFailure(
                            reservation.operationId(),
                            operationResult.mensaje()
                    );
                    return operationResult;
                }

                String identifier = operationResult.datos() == null
                        ? null
                        : operationResult.datos().toString();

                complete(
                        reservation.operationId(),
                        entitySchema,
                        entityName,
                        identifier,
                        operationResult.codigo()
                );

                return operationResult;
            });

            if (result == null) {
                throw new IllegalStateException(
                        "No se obtuvo resultado de la transacción idempotente."
                );
            }

            return result;
        } catch (RuntimeException exception) {
            log.error(
                    "Fallo en idempotencia SQL. userId={} scope={} key={} error={}",
                    userId,
                    normalizedScope,
                    idempotencyKey,
                    exception.getClass().getSimpleName(),
                    exception
            );

            return PersistenceResult.error(
                    TECHNICAL_CODE,
                    TECHNICAL_MESSAGE,
                    503
            );
        }
    }

    private void ensurePhysicalSqlServerTransaction() {
        Integer transactionCount = jdbc.queryForObject(
                "SELECT @@TRANCOUNT",
                Integer.class
        );

        if (transactionCount == null || transactionCount == 0) {
            jdbc.execute("BEGIN TRANSACTION");
        }
    }

    private void acquireLock(
            Long userId,
            String scope,
            UUID idempotencyKey
    ) {
        String resource = "DESCO:IDEMPOTENCIA:"
                + userId
                + ':'
                + scope
                + ':'
                + idempotencyKey;

        Integer result = jdbc.queryForObject(
                LOCK_SQL,
                Integer.class,
                resource
        );

        if (result == null || result < 0) {
            throw new IllegalStateException(
                    "No se pudo reservar la operación idempotente. Código SQL Server: "
                            + result
            );
        }
    }

    private Reservation reserve(
            Long userId,
            UUID idempotencyKey,
            String scope
    ) {
        return jdbc.queryForObject(
                RESERVE_SQL,
                (resultSet, rowNum) -> reservation(resultSet),
                userId,
                idempotencyKey.toString(),
                scope
        );
    }

    private Reservation reservation(ResultSet resultSet) throws SQLException {
        Long operationId = nullableLong(resultSet, "operacionId");
        Boolean repeated = nullableBoolean(resultSet, "repetida");
        Boolean accepted = nullableBoolean(resultSet, "resultado");
        Integer http = nullableInteger(resultSet, "httpRespuesta");

        return new Reservation(
                operationId,
                Boolean.TRUE.equals(repeated),
                trim(resultSet.getString("estadoOperacion")),
                trim(resultSet.getString("identificadorResultado")),
                trim(resultSet.getString("codigoResultado")),
                Boolean.TRUE.equals(accepted),
                trim(resultSet.getString("mensaje")),
                trim(resultSet.getString("codigoRespuesta")),
                http,
                trim(resultSet.getString("mensajeGuardado"))
        );
    }

    private <T> PersistenceResult<T> rejectedReservation(
            Reservation reservation
    ) {
        String code = hasText(reservation.responseCode())
                ? reservation.responseCode()
                : "IDEMPOTENCIA_RECHAZADA";

        String message = hasText(reservation.message())
                ? reservation.message()
                : "No se pudo reservar la operación.";

        int http = reservation.httpStatus() == null
                ? 409
                : reservation.httpStatus();

        return PersistenceResult.error(
                code,
                message,
                http
        );
    }

    private <T> PersistenceResult<T> replay(
            Reservation reservation,
            Function<String, T> replayValue
    ) {
        String state = reservation.state();

        if ("COMPLETADA".equalsIgnoreCase(state)) {
            T data = replayValue.apply(
                    reservation.resultIdentifier()
            );

            return PersistenceResult.ok(
                    null,
                    "La solicitud ya fue procesada correctamente.",
                    200,
                    data
            );
        }

        if ("FALLIDA".equalsIgnoreCase(state)) {
            String message = hasText(reservation.savedMessage())
                    ? reservation.savedMessage()
                    : "La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.";

            return PersistenceResult.error(
                    "OPERACION_ANTERIOR_FALLIDA",
                    message,
                    400
            );
        }

        return PersistenceResult.error(
                "OPERACION_EN_PROCESO",
                "La solicitud todavía se está procesando. Intente nuevamente.",
                409
        );
    }

    private void complete(
            Long operationId,
            String entitySchema,
            String entityName,
            String identifier,
            String resultCode
    ) {
        if (operationId == null) {
            throw new IllegalStateException(
                    "No existe una reserva idempotente para finalizar."
            );
        }

        Completion completion = jdbc.queryForObject(
                COMPLETE_SQL,
                (resultSet, rowNum) -> new Completion(
                        resultSet.getBoolean("resultado"),
                        trim(resultSet.getString("mensaje"))
                ),
                operationId,
                normalize(entitySchema),
                normalize(entityName),
                normalize(identifier),
                limit(normalize(resultCode), 40)
        );

        if (completion == null || !completion.success()) {
            throw new IllegalStateException(
                    completion == null || !hasText(completion.message())
                            ? "No se pudo finalizar la operación idempotente."
                            : completion.message()
            );
        }
    }

    private void rememberFailure(
            Long operationId,
            String message
    ) {
        if (operationId == null) {
            return;
        }

        try {
            jdbc.queryForObject(
                    FAIL_SQL,
                    (resultSet, rowNum) -> resultSet.getBoolean("resultado"),
                    operationId,
                    limit(
                            hasText(message)
                                    ? message.trim()
                                    : "La acción no se completó.",
                            300
                    )
            );
        } catch (RuntimeException exception) {
            log.warn(
                    "No se pudo guardar el mensaje de una operación idempotente fallida. operationId={}",
                    operationId,
                    exception
            );
        }
    }

    private Long parseLongReplay(String value) {
        if (!hasText(value)) {
            throw new IllegalStateException(
                    "La operación completada no conserva su identificador de resultado."
            );
        }

        try {
            return Long.valueOf(value.trim());
        } catch (NumberFormatException exception) {
            throw new IllegalStateException(
                    "El identificador conservado por idempotencia no es numérico.",
                    exception
            );
        }
    }

    private static Long nullableLong(
            ResultSet resultSet,
            String column
    ) throws SQLException {
        long value = resultSet.getLong(column);
        return resultSet.wasNull() ? null : value;
    }

    private static Integer nullableInteger(
            ResultSet resultSet,
            String column
    ) throws SQLException {
        int value = resultSet.getInt(column);
        return resultSet.wasNull() ? null : value;
    }

    private static Boolean nullableBoolean(
            ResultSet resultSet,
            String column
    ) throws SQLException {
        boolean value = resultSet.getBoolean(column);
        return resultSet.wasNull() ? null : value;
    }

    private static String normalize(String value) {
        return hasText(value) ? value.trim() : null;
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }

    private static String limit(
            String value,
            int max
    ) {
        if (value == null || value.length() <= max) {
            return value;
        }
        return value.substring(0, max);
    }

    private static boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private record Reservation(
            Long operationId,
            boolean repeated,
            String state,
            String resultIdentifier,
            String resultCode,
            boolean accepted,
            String message,
            String responseCode,
            Integer httpStatus,
            String savedMessage
    ) {
    }

    private record Completion(
            boolean success,
            String message
    ) {
    }
}
