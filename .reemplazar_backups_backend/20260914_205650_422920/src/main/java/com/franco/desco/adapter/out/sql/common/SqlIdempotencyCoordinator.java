package com.franco.desco.adapter.out.sql.common;

import com.franco.desco.application.shared.PersistenceResult;
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
    private final JdbcTemplate jdbc;
    private final TransactionTemplate transaction;

    public SqlIdempotencyCoordinator(JdbcTemplate jdbc, PlatformTransactionManager transactionManager) {
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
        if (key == null) return PersistenceResult.error("La clave de idempotencia es obligatoria.");
        try {
            return transaction.execute(status -> {
                acquireLock("DESCO:IDEMPOTENCY:" + key);
                Existing existing = existing(key);
                if (existing != null) {
                    if (!existing.userId().equals(userId) || !existing.scope().equals(scope)) {
                        return PersistenceResult.error("La clave de idempotencia ya fue utilizada por otra operación.");
                    }
                    if ("COMPLETADA".equals(existing.status()) && existing.resultId() != null) {
                        try {
                            return PersistenceResult.ok("La operación ya fue procesada correctamente.", Long.valueOf(existing.resultId()));
                        } catch (NumberFormatException ignored) {
                            return PersistenceResult.error("No se pudo recuperar el resultado de la operación anterior.");
                        }
                    }
                    return PersistenceResult.error("La operación con esta clave todavía está siendo procesada.");
                }

                jdbc.update("""
                        INSERT auditoria.OperacionIdempotente
                        (usuario_id,clave_idempotencia,ambito,fecha_inicio,estado_operacion,fecha_expiracion,estado)
                        VALUES(?,?,?,SYSUTCDATETIME(),'EN_PROCESO',DATEADD(day,7,SYSUTCDATETIME()),1)
                        """, userId, key, scope);

                PersistenceResult<Long> result = operation.get();
                if (result == null || !result.exitoso() || result.datos() == null) {
                    status.setRollbackOnly();
                    return result == null ? PersistenceResult.error("No se pudo completar la operación.") : result;
                }

                jdbc.update("""
                        UPDATE auditoria.OperacionIdempotente
                        SET estado_operacion='COMPLETADA',fecha_fin=SYSUTCDATETIME(),esquema_entidad=?,nombre_entidad=?,
                            identificador_resultado=?,codigo_resultado=?,mensaje_resultado=?
                        WHERE usuario_id=? AND clave_idempotencia=? AND ambito=?
                        """, entitySchema, entityName, String.valueOf(result.datos()), result.codigo(), result.mensaje(), userId, key, scope);
                return result;
            });
        } catch (DataAccessException | IllegalStateException exception) {
            return PersistenceResult.error("No se pudo completar la operación en este momento.");
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
        if (key == null) return PersistenceResult.error("La clave de idempotencia es obligatoria.");
        try {
            return transaction.execute(status -> {
                acquireLock("DESCO:IDEMPOTENCY:" + key);
                Existing existing = existing(key);
                if (existing != null) {
                    if (!existing.userId().equals(userId) || !existing.scope().equals(scope)) {
                        return PersistenceResult.error("La clave de idempotencia ya fue utilizada por otra operación.");
                    }
                    if ("COMPLETADA".equals(existing.status())) {
                        return PersistenceResult.ok("La operación ya fue procesada correctamente.", null);
                    }
                    return PersistenceResult.error("La operación con esta clave todavía está siendo procesada.");
                }

                jdbc.update("""
                        INSERT auditoria.OperacionIdempotente
                        (usuario_id,clave_idempotencia,ambito,fecha_inicio,estado_operacion,fecha_expiracion,estado)
                        VALUES(?,?,?,SYSUTCDATETIME(),'EN_PROCESO',DATEADD(day,7,SYSUTCDATETIME()),1)
                        """, userId, key, scope);

                PersistenceResult<Void> result = operation.get();
                if (result == null || !result.exitoso()) {
                    status.setRollbackOnly();
                    return result == null ? PersistenceResult.error("No se pudo completar la operación.") : result;
                }

                jdbc.update("""
                        UPDATE auditoria.OperacionIdempotente
                        SET estado_operacion='COMPLETADA',fecha_fin=SYSUTCDATETIME(),esquema_entidad=?,nombre_entidad=?,
                            codigo_resultado=?,mensaje_resultado=?
                        WHERE usuario_id=? AND clave_idempotencia=? AND ambito=?
                        """, entitySchema, entityName, result.codigo(), result.mensaje(), userId, key, scope);
                return result;
            });
        } catch (DataAccessException | IllegalStateException exception) {
            return PersistenceResult.error("No se pudo completar la operación en este momento.");
        }
    }

    private Existing existing(UUID key) {
        List<Existing> values = jdbc.query("""
                SELECT usuario_id,ambito,estado_operacion,identificador_resultado
                FROM auditoria.OperacionIdempotente WHERE clave_idempotencia=? AND estado=1
                """, (rs, rowNum) -> new Existing(rs.getLong(1), rs.getString(2), rs.getString(3), rs.getString(4)), key);
        return values.isEmpty() ? null : values.getFirst();
    }

    private void acquireLock(String resource) {
        Integer result = jdbc.queryForObject("DECLARE @r int; EXEC @r=sp_getapplock @Resource=?,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000; SELECT @r;", Integer.class, resource);
        if (result == null || result < 0) throw new IllegalStateException("No se pudo reservar la operación idempotente.");
    }

    private record Existing(Long userId, String scope, String status, String resultId) {}
}
