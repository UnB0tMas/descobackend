package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.PersistenceResult;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public record PaExecution(
        boolean exitoso,
        String codigo,
        String mensaje,
        Integer httpSugerido,
        List<List<Map<String, Object>>> resultSets,
        Map<String, Object> outputs
) {
    public PaExecution {
        resultSets = resultSets == null
                ? List.of()
                : List.copyOf(resultSets);
        /*
         * Los parámetros OUTPUT de SQL Server pueden ser NULL por contrato.
         * Map.copyOf(...) rechaza valores null y convertía una respuesta
         * funcional válida del PA (por ejemplo, un OTP inválido sin sesión)
         * en NullPointerException/HTTP 500.
         *
         * Se conserva una copia inmutable, pero permitiendo valores null.
         */
        outputs = outputs == null || outputs.isEmpty()
                ? Map.of()
                : Collections.unmodifiableMap(
                        new LinkedHashMap<>(outputs)
                );
    }

    public <T> PersistenceResult<T> toPersistence(
            T data
    ) {
        if (exitoso) {
            return PersistenceResult.ok(
                    codigo,
                    mensaje,
                    httpSugerido,
                    data
            );
        }

        return PersistenceResult.error(
                codigo,
                mensaje,
                httpSugerido
        );
    }
}
