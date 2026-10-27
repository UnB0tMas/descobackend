package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.shared.PersistenceResult;

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
        outputs = outputs == null
                ? Map.of()
                : Map.copyOf(outputs);
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
