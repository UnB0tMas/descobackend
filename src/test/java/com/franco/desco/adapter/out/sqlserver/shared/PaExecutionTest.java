package com.franco.desco.adapter.out.sqlserver.shared;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PaExecutionTest {

    @Test
    void preservesNullableOutputParametersWithoutThrowing() {
        Map<String, Object> outputs = new LinkedHashMap<>();
        outputs.put("sesionUsuarioId", null);
        outputs.put("sesionPublicaId", null);
        outputs.put("resultado", false);
        outputs.put("mensaje", "El código ingresado no es válido o ha expirado.");

        PaExecution execution = new PaExecution(
                false,
                "CODIGO_NO_VALIDO",
                "El código ingresado no es válido o ha expirado.",
                401,
                List.of(),
                outputs
        );

        assertTrue(execution.outputs().containsKey("sesionUsuarioId"));
        assertNull(execution.outputs().get("sesionUsuarioId"));
        assertTrue(execution.outputs().containsKey("sesionPublicaId"));
        assertNull(execution.outputs().get("sesionPublicaId"));
        assertThrows(
                UnsupportedOperationException.class,
                () -> execution.outputs().put("otro", 1)
        );
    }
}
