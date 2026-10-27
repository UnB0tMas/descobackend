package com.franco.desco.application.shared;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ApplicationResultsTest {

    @Test
    void debeUsarCodigoMensajeYHttpEntregadosPorLaBase() {
        PersistenceResult<Void> persistence =
                new PersistenceResult<>(
                        false,
                        "CORREO_DUPLICADO",
                        "El correo ya está registrado.",
                        409,
                        null
                );

        AppResult<Void> result =
                ApplicationResults.ok(
                        persistence,
                        "ACTUALIZADO",
                        "NO_ACTUALIZADO",
                        AppStatus.BAD_REQUEST
                );

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("CORREO_DUPLICADO");
        assertThat(result.mensaje()).isEqualTo("El correo ya está registrado.");
        assertThat(result.estado()).isEqualTo(AppStatus.CONFLICT);
    }

    @Test
    void debeConservarFallbackCuandoLaBaseNoEntregaCodigoNiHttp() {
        PersistenceResult<Void> persistence =
                PersistenceResult.error(
                        "No se pudo completar la acción."
                );

        AppResult<Void> result =
                ApplicationResults.ok(
                        persistence,
                        "ACTUALIZADO",
                        "NO_ACTUALIZADO",
                        AppStatus.BAD_REQUEST
                );

        assertThat(result.codigo()).isEqualTo("NO_ACTUALIZADO");
        assertThat(result.estado()).isEqualTo(AppStatus.BAD_REQUEST);
    }
}
