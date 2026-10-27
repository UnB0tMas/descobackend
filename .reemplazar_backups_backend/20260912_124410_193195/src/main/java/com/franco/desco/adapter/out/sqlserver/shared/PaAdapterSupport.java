package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.pagination.PageResult;

import java.util.List;
import java.util.Map;
import java.util.function.Function;

public final class PaAdapterSupport {

    private PaAdapterSupport() {
    }

    public static boolean success(Map<String, Object> output) {
        return SqlValues.bool(output, "bResultado");
    }

    public static String message(Map<String, Object> output, String fallback) {
        String message = SqlValues.string(output, "cMensaje");
        return message == null || message.isBlank() ? fallback : message;
    }

    public static <T> PersistenceResult<T> result(
            Map<String, Object> output,
            T data,
            String fallback
    ) {
        if (!success(output)) {
            return PersistenceResult.error(message(output, fallback));
        }
        return PersistenceResult.ok(message(output, fallback), data);
    }

    public static <T> PersistenceResult<PageResult<T>> page(
            Map<String, Object> output,
            List<Map<String, Object>> rows,
            int page,
            int size,
            Function<Map<String, Object>, T> mapper,
            String fallback
    ) {
        if (!success(output)) {
            return PersistenceResult.error(message(output, fallback));
        }

        List<T> items = rows.stream().map(mapper).toList();
        long total = rows.isEmpty() ? 0L : valueOrZero(SqlValues.longValue(rows.getFirst(), "totalRegistros"));
        int normalizedSize = size <= 0 ? 20 : Math.min(size, 100);
        int normalizedPage = page <= 0 ? 1 : page;
        int totalPages = normalizedSize == 0 ? 0 : (int) Math.ceil((double) total / normalizedSize);

        return PersistenceResult.ok(
                message(output, fallback),
                new PageResult<>(items, normalizedPage, normalizedSize, total, totalPages)
        );
    }

    private static long valueOrZero(Long value) {
        return value == null ? 0L : value;
    }
}
