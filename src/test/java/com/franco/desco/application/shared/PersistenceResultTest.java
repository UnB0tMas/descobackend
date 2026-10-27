package com.franco.desco.application.shared;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PersistenceResultTest {

    @Test
    void noDebeExponerMensajesTecnicosComoMensajePublico() {
        PersistenceResult<Void> result =
                new PersistenceResult<>(
                        false,
                        "ERROR_PERSISTENCIA",
                        "SQLException 2627 duplicate key dbo.Tabla IX_X",
                        500,
                        null
                );

        assertThat(result.mensaje())
                .isEqualTo("No se pudo completar la acción.");
    }

    @Test
    void debeConservarMensajeFuncional() {
        PersistenceResult<Void> result =
                new PersistenceResult<>(
                        false,
                        "REGISTRO_DUPLICADO",
                        "La información ya se encuentra registrada.",
                        409,
                        null
                );

        assertThat(result.mensaje())
                .isEqualTo("La información ya se encuentra registrada.");
    }
}
