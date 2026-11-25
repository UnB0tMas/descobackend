package com.franco.desco.adapter.in.web.sanitation;

import org.junit.jupiter.api.Test;
import jakarta.validation.Validation;

import java.math.BigDecimal;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class SanitationTreatmentE2ValidationTest {
    private SanitationRequests.Treatment nuevo(Long salida, Long recurso, Long programacion, Long visita) {
        return new SanitationRequests.Treatment(visita, 5L,
                Instant.parse("2026-11-22T10:00:00Z"), "Tratamiento", "Calcio",
                null, null, null, programacion, new BigDecimal("0.300"),
                salida, recurso, "L");
    }

    @Test
    void rechazoConsumoE2SinVisita() {
        assertThat(nuevo(10L, 12L, null, null).isConsumoCompleto()).isFalse();
        assertThat(nuevo(10L, 12L, null, 20L).isConsumoCompleto()).isTrue();
    }

    @Test
    void impideCombinarProgramacionHistoricaYRecursoE2() {
        assertThat(nuevo(10L, 12L, 40L, 20L).isConsumoCompleto()).isFalse();
        assertThat(nuevo(null, null, 40L, null).isConsumoCompleto()).isTrue();
    }

    @Test
    void validaDosisYUnidadComoParejaEnLaPeticion() {
        var peticion = new SanitationRequests.Treatment(20L, 5L,
                Instant.parse("2026-11-22T10:00:00Z"), "Tratamiento", "Calcio",
                new BigDecimal("1.25"), null, null, null, null, null, null, null);
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var campos = factory.getValidator().validate(peticion).stream()
                    .map(error -> error.getPropertyPath().toString()).toList();
            assertThat(campos).contains("dosisCompleta");
        }
    }
}
