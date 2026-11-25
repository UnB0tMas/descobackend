package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.sql.SQLException;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * Trazabilidad común de procedimientos almacenados.
 * No altera parámetros, valores devueltos, transacciones ni excepciones.
 */
public final class PaTrace {
    private static final Logger LOG = LoggerFactory.getLogger(PaTrace.class);
    private static final int MAX_DETAIL = 350;

    /** Solo lecturas y mantenimientos periodicos, nunca los PA invocados por una solicitud HTTP. */
    private static final Set<String> QUIET_BACKGROUND_PROCEDURES = Set.of(
            "seg.pa_seguridad_sel_notificacionespendientes",
            "comercial.pa_venta_upd_vencerreservas",
            "comercial.pa_campaniaventa_upd_vencer",
            "reporte.pa_excel_trabajo_reservar",
            "reporte.pa_excel_sel_filas",
            "reporte.pa_excel_trabajo_finalizar",
            "reporte.pa_excel_trabajo_purgar",
            "reporte.pa_reportetemporal_purgar",
            "reporte.pa_informeespecial_filas",
            "reporte.pa_informesanitario_contenido"
    );

    private PaTrace() {
    }

    public static <T> T call(String procedure, Supplier<T> execution) {
        return call(procedure, operationName(procedure), execution, PaTrace::successful, PaTrace::detail);
    }

    public static <T> T call(String procedure, String operation, Supplier<T> execution) {
        return call(procedure, operation, execution, PaTrace::successful, PaTrace::detail);
    }

    public static <T> T call(String procedure, Supplier<T> execution,
                             Predicate<? super T> successful,
                             Function<? super T, String> detail) {
        return call(procedure, operationName(procedure), execution, successful, detail);
    }

    public static <T> T call(String procedure, String operation, Supplier<T> execution,
                             Predicate<? super T> successful,
                             Function<? super T, String> detail) {
        String name = procedureName(procedure);
        String action = safeOperation(operation, name);
        String correlationId = correlationId();
        boolean quietRoutine = quietRoutine(name, correlationId);
        long started = System.nanoTime();

        if (!quietRoutine) {
            LOG.info(">> [PA INICIADO] procedimiento={} accion={} correlacionId={}",
                    name, action, correlationId);
        }
        try {
            T result = execution.get();
            long millis = elapsedMillis(started);
            if (successful.test(result)) {
                if (!quietRoutine) {
                    LOG.info(">> [PA EXITOSO] procedimiento={} accion={} resultado={} http={} "
                                    + "duracionMs={} correlacionId={}",
                            name, action, confirmation(result), httpStatus(result), millis, correlationId);
                }
            } else if (technicalFailure(result)) {
                LOG.error(">> [PA ERROR SQL/TECNICO] procedimiento={} accion={} http={} "
                                + "detalle={} duracionMs={} correlacionId={}",
                        name, action, httpStatus(result), safe(detail.apply(result)), millis, correlationId);
            } else {
                LOG.warn(">> [PA ERROR FUNCIONAL] procedimiento={} accion={} http={} "
                                + "detalle={} duracionMs={} correlacionId={}",
                        name, action, httpStatus(result), safe(detail.apply(result)), millis, correlationId);
            }
            return result;
        } catch (RuntimeException | Error exception) {
            SQLException sql = findSqlException(exception);
            LOG.error(">> [PA ERROR SQL/TECNICO] procedimiento={} accion={} "
                            + "codigoSQL={} estadoSQL={} detalle={} duracionMs={} correlacionId={}",
                    name, action, sql == null ? "-" : sql.getErrorCode(),
                    sql == null ? "-" : sql.getSQLState(), safe(exception.getMessage()),
                    elapsedMillis(started), correlationId, exception);
            throw exception;
        }
    }

    public static void run(String procedure, Runnable execution) {
        call(procedure, () -> {
            execution.run();
            return Boolean.TRUE;
        });
    }

    public static String procedureName(String call) {
        if (call == null || call.isBlank()) {
            return "PA_DESCONOCIDO";
        }
        String normalized = call.trim();
        if (normalized.regionMatches(true, 0, "{call ", 0, 6)) {
            normalized = normalized.substring(6);
        } else if (normalized.regionMatches(true, 0, "EXECUTE ", 0, 8)) {
            normalized = normalized.substring(8);
        } else if (normalized.regionMatches(true, 0, "EXEC ", 0, 5)) {
            normalized = normalized.substring(5);
        }
        int parameters = normalized.indexOf('(');
        if (parameters >= 0) {
            normalized = normalized.substring(0, parameters);
        }
        int space = normalized.indexOf(' ');
        if (space >= 0) {
            normalized = normalized.substring(0, space);
        }
        return normalized.replace("[", "").replace("]", "")
                .replace("}", "").trim();
    }

    /** Los PA exceptuados conservan sus errores en WARN/ERROR y sus logs ante solicitudes HTTP. */
    static boolean quietRoutine(String procedure, String correlationId) {
        return "-".equals(correlationId)
                && QUIET_BACKGROUND_PROCEDURES.contains(
                        procedureName(procedure).toLowerCase(Locale.ROOT));
    }

    /** Acción predeterminada para PA que no reciben una acción interna. */
    public static String operationName(String procedure) {
        String name = procedureName(procedure).toUpperCase(Locale.ROOT);
        if (name.contains("_SEL_") || name.contains("_SEL") || name.contains("_VAL_")) {
            return "CONSULTAR";
        }
        if (name.contains("_INS_") || name.contains("_INS")) {
            return "REGISTRAR";
        }
        if (name.contains("_UPD_") || name.contains("_UPD")) {
            return "ACTUALIZAR";
        }
        if (name.contains("_DEL_") || name.contains("_DEL")) {
            return "ELIMINAR";
        }
        return "EJECUTAR";
    }

    private static String safeOperation(String operation, String procedure) {
        String value = operation == null || operation.isBlank()
                ? operationName(procedure) : operation.trim();
        return value.matches("[\\w-]{1,70}") ? value : "EJECUTAR";
    }

    private static String confirmation(Object result) {
        if (result instanceof PaExecution execution) {
            return hasStatus(execution.outputs()) ? "FUNCIONAL" : "SQL_SIN_BANDERA";
        }
        if (result instanceof PersistenceResult<?> || result instanceof AppResult<?>
                || result instanceof Boolean) {
            return "FUNCIONAL";
        }
        if (result instanceof Map<?, ?> values) {
            return hasStatus(values) ? "FUNCIONAL" : "SQL_SIN_BANDERA";
        }
        return "SQL_SIN_BANDERA";
    }

    private static boolean hasStatus(Map<?, ?> values) {
        return hasKey(values, "bResultado", "exitoso", "resultado");
    }

    private static boolean technicalFailure(Object result) {
        if (result instanceof PaExecution execution) {
            return execution.httpSugerido() >= 500;
        }
        if (result instanceof PersistenceResult<?> execution) {
            return execution.httpSugerido() >= 500;
        }
        if (result instanceof AppResult<?> execution) {
            return httpStatus(execution.estado()) >= 500;
        }
        return false;
    }

    private static boolean successful(Object result) {
        if (result == null) {
            return false;
        }
        if (result instanceof PaExecution execution) {
            return execution.exitoso();
        }
        if (result instanceof PersistenceResult<?> execution) {
            return execution.exitoso();
        }
        if (result instanceof AppResult<?> execution) {
            return execution.exitoso();
        }
        if (result instanceof Boolean success) {
            return success;
        }
        if (result instanceof Map<?, ?> values) {
            Object status = find(values, "bResultado", "exitoso", "resultado");
            if (hasStatus(values) && status == null) {
                return false;
            }
            if (status instanceof Boolean bool) {
                return bool;
            }
            if (status instanceof Number number) {
                return number.intValue() != 0;
            }
            if (status instanceof String value) {
                return "1".equals(value.trim()) || "true".equalsIgnoreCase(value.trim())
                        || "si".equalsIgnoreCase(value.trim()) || "sí".equalsIgnoreCase(value.trim());
            }
            if (hasStatus(values)) {
                return false;
            }
        }
        // Sin bandera funcional: únicamente se confirma que no hubo excepción SQL.
        return true;
    }

    private static String detail(Object result) {
        if (result == null) {
            return "El PA no devolvió un resultado.";
        }
        if (result instanceof PaExecution execution) {
            return "codigo=" + execution.codigo() + " mensaje=" + execution.mensaje();
        }
        if (result instanceof PersistenceResult<?> execution) {
            return "codigo=" + execution.codigo() + " mensaje=" + execution.mensaje();
        }
        if (result instanceof AppResult<?> execution) {
            return "codigo=" + execution.codigo() + " mensaje=" + execution.mensaje();
        }
        if (result instanceof Boolean success) {
            return "bResultado=" + success;
        }
        if (result instanceof Map<?, ?> values) {
            return "codigo=" + find(values, "cCodigoRespuesta", "codigoRespuesta", "codigo")
                    + " mensaje=" + find(values, "cMensaje", "mensaje");
        }
        return "Resultado funcional negativo";
    }

    private static String httpStatus(Object result) {
        if (result instanceof PaExecution execution) {
            return number(execution.httpSugerido());
        }
        if (result instanceof PersistenceResult<?> execution) {
            return number(execution.httpSugerido());
        }
        if (result instanceof AppResult<?> execution) {
            return String.valueOf(httpStatus(execution.estado()));
        }
        if (result instanceof Map<?, ?> values) {
            Object code = find(values, "nHttpRespuesta", "httpSugerido", "httpRespuesta");
            return code == null ? "-" : safe(String.valueOf(code));
        }
        return "-";
    }

    private static int httpStatus(AppStatus status) {
        return switch (status) {
            case OK -> 200;
            case CREATED -> 201;
            case BAD_REQUEST -> 400;
            case UNAUTHORIZED -> 401;
            case FORBIDDEN -> 403;
            case NOT_FOUND -> 404;
            case CONFLICT -> 409;
            case TOO_MANY_REQUESTS -> 429;
            case SERVICE_UNAVAILABLE -> 503;
            case INTERNAL_ERROR -> 500;
        };
    }

    private static String number(Number value) {
        return value == null ? "-" : value.toString();
    }

    private static Object find(Map<?, ?> values, String... keys) {
        Map.Entry<?, ?> entry = findEntry(values, keys);
        return entry == null ? null : entry.getValue();
    }

    private static boolean hasKey(Map<?, ?> values, String... keys) {
        return findEntry(values, keys) != null;
    }

    private static Map.Entry<?, ?> findEntry(Map<?, ?> values, String... keys) {
        for (Map.Entry<?, ?> entry : values.entrySet()) {
            String candidate = normalizeKey(entry.getKey());
            for (String key : keys) {
                if (candidate.equals(normalizeKey(key))) {
                    return entry;
                }
            }
        }
        return null;
    }

    private static String normalizeKey(Object key) {
        return String.valueOf(key).replace("_", "").replace("@", "")
                .trim().toLowerCase(Locale.ROOT);
    }

    private static SQLException findSqlException(Throwable failure) {
        Throwable current = failure;
        while (current != null) {
            if (current instanceof SQLException sql) {
                return sql;
            }
            if (current.getCause() == current) {
                break;
            }
            current = current.getCause();
        }
        return null;
    }

    private static String safe(String message) {
        if (message == null) {
            return "Sin detalle adicional";
        }
        String singleLine = message.replace('\r', ' ').replace('\n', ' ');
        return singleLine.length() <= MAX_DETAIL ? singleLine : singleLine.substring(0, MAX_DETAIL);
    }

    private static long elapsedMillis(long started) {
        return (System.nanoTime() - started) / 1_000_000;
    }

    private static String correlationId() {
        String value = MDC.get("correlationId");
        return value == null || value.isBlank() ? "-" : value;
    }
}
