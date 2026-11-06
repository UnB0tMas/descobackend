package com.franco.desco.adapter.in.web.planta;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class E3WebTypesTest {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void loteHassFuerteNoExigeFichaEdadNiProduccion() {
        var solicitud = new E3WebTypes.Lote(List.of(
                new E3WebTypes.Fila(1L, 120, null),
                new E3WebTypes.Fila(2L, 50, null)), null);
        assertThat(validator.validate(solicitud)).isEmpty();
        assertThat(solicitud.filas().stream().mapToInt(E3WebTypes.Fila::cantidad).sum()).isEqualTo(170);
    }

    @Test
    void rechazaCantidadInvalidaAntesDeConsultarBD() {
        var solicitud = new E3WebTypes.Lote(List.of(new E3WebTypes.Fila(1L, 0, null)), null);
        assertThat(validator.validate(solicitud)).isNotEmpty();
    }

    @Test
    void exigeTipoDeProduccionYPermiteCosechaSeparadaDeEstimacion() {
        var cosecha = new E3WebTypes.Produccion(2026, "COSECHA", null,
                new BigDecimal("75.250"), null, null, null);
        assertThat(validator.validate(cosecha)).isEmpty();
        assertThat(validator.validate(new E3WebTypes.Produccion(2026, null, null,
                new BigDecimal("75.250"), null, null, null))).isNotEmpty();
    }

    @Test
    void fichaProgressivaNoRequiereEdadNiProduccion() {
        var ficha = new E3WebTypes.Ficha(null, null, 0L);
        assertThat(validator.validate(ficha)).isEmpty();
    }

    @Test
    void estadoYSeguimientoUsanContratosTipados() {
        var estado = new E3WebTypes.Estado("ENFERMA", 2L, "Diagnóstico", 5L,
                null, 0L, false, null);
        var seguimiento = new E3WebTypes.Seguimiento("Se podó rama seca",
                "PODA", null, 5L, null);
        assertThat(validator.validate(estado)).isEmpty();
        assertThat(validator.validate(seguimiento)).isEmpty();
        assertThat(validator.validate(new E3WebTypes.Seguimiento("Observación", "INVALIDO",
                null, 5L, null))).isNotEmpty();
    }
}
