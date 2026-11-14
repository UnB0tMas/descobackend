package com.franco.desco.application.expediente.service;

import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.expediente.port.out.E1PersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.expediente.E1Models;
import org.junit.jupiter.api.Test;

import java.util.UUID;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class E1ApplicationServiceTest {
    private final E1PersistencePort persistence = mock(E1PersistencePort.class);
    private final E1ApplicationService service = new E1ApplicationService(persistence);
    private final SessionIdentity identity = new SessionIdentity(10L, UUID.randomUUID(), 1, "test");
    private final RequestMetadata metadata = new RequestMetadata(
            UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), "127.0.0.1",
            "/api/v1/expedientes-productivos", "test", "test", "test", "test"
    );

    @Test
    void noConsultaSinUotValida() {
        var result = service.listPredios(new E1Commands.ListPredios(null, null, null), identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("CONTEXTO_INVALIDO");
        verifyNoInteractions(persistence);
    }

    @Test
    void listadoVacioValidoSeDevuelveComoArregloVacio() {
        when(persistence.listPredios(any(), any(), any()))
                .thenReturn(PersistenceResult.ok("EXPEDIENTE_OK", "Consulta correcta", 200,
                        new E1Models.Predios(List.of())));
        var result = service.listPredios(new E1Commands.ListPredios(1L, null, null), identity, metadata);
        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos().items()).isEmpty();
    }

    @Test
    void listadoConDatosConservaLosPredios() {
        var predio = new E1Models.PredioResumen(15L, "PR015", "Predio de prueba", "050101",
                "Referencia", null, null, "Titular");
        when(persistence.listPredios(any(), any(), any()))
                .thenReturn(PersistenceResult.ok("EXPEDIENTE_OK", "Consulta correcta", 200,
                        new E1Models.Predios(List.of(predio))));
        var result = service.listPredios(new E1Commands.ListPredios(1L, null, null), identity, metadata);
        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos().items()).containsExactly(predio);
    }

    @Test
    void listadoSinItemsEsErrorDeContratoYNoSeDisfrazaComoVacio() {
        when(persistence.listPredios(any(), any(), any()))
                .thenReturn(PersistenceResult.ok("EXPEDIENTE_OK", "Consulta correcta", 200,
                        new E1Models.Predios(null)));
        var result = service.listPredios(new E1Commands.ListPredios(1L, null, null), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("EXPEDIENTE_RESPUESTA_INVALIDA");
        assertThat(result.estado()).isEqualTo(AppStatus.INTERNAL_ERROR);
    }

    @Test
    void listadoSinObjetoEsErrorDeContrato() {
        when(persistence.listPredios(any(), any(), any()))
                .thenReturn(PersistenceResult.<E1Models.Predios>ok("EXPEDIENTE_OK", "Consulta correcta", 200, null));
        var result = service.listPredios(new E1Commands.ListPredios(1L, null, null), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("EXPEDIENTE_RESPUESTA_INVALIDA");
    }

    @Test
    void falloDeBaseDeDatosNoSeConvierteEnListadoVacio() {
        when(persistence.listPredios(any(), any(), any()))
                .thenReturn(PersistenceResult.error("EXPEDIENTE_PROHIBIDO", "Acceso denegado", 403));
        var result = service.listPredios(new E1Commands.ListPredios(1L, null, null), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.estado()).isEqualTo(AppStatus.FORBIDDEN);
    }

    @Test
    void evitaBusquedasMasivasDeIdentidad() {
        var result = service.searchPersonas(new E1Commands.SearchPersonas(1L, "ab"), identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("BUSQUEDA_INVALIDA");
        verifyNoInteractions(persistence);
    }

    @Test
    void noCreaVersionTecnicaVacia() {
        var command = new E1Commands.CompleteFicha(1L, null, 5L,
                new E1Commands.Ficha(null, null, " "));

        var result = service.completeFicha(command, identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("FICHA_SIN_CAMBIOS");
        verifyNoInteractions(persistence);
    }

    @Test
    void conservaLaAutorizacionResueltaEnSqlServer() {
        when(persistence.getExpediente(any(), any(), any()))
                .thenReturn(PersistenceResult.error("EXPEDIENTE_PROHIBIDO", "No tiene acceso a este ámbito.", 403));

        var result = service.getExpediente(new E1Commands.GetExpediente(1L, 7L, 5L), identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.estado()).isEqualTo(AppStatus.FORBIDDEN);
    }

    @Test
    void devuelveElExpedienteTipadoSinContratoGenerico() {
        var data = new E1Models.Expediente(
                5L, "PRE-5", "Fundo", "050101", null,
                null, null, null, null, null, null,
                null, false, java.util.List.of(), java.util.List.of(),
                java.util.List.of(), java.util.List.of(), java.util.List.of(), java.util.List.of()
        );
        when(persistence.getExpediente(any(), any(), any()))
                .thenReturn(PersistenceResult.ok("EXPEDIENTE_OK", "Expediente recuperado.", 200, data));

        var result = service.getExpediente(new E1Commands.GetExpediente(1L, null, 5L), identity, metadata);

        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos()).isSameAs(data);
    }
}
