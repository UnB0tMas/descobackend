package com.franco.desco.application.fieldtrip.service;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.out.E2PersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.fieldtrip.E2Models;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class E2ApplicationServiceTest {
    private final E2PersistencePort port = mock(E2PersistencePort.class);
    private final E2ApplicationService service = new E2ApplicationService(port, mock(com.franco.desco.application.fieldtrip.document.E2DocumentService.class));
    private final SessionIdentity identity = new SessionIdentity(10L, UUID.randomUUID(), 1, "test");
    private final RequestMetadata metadata = new RequestMetadata(UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "127.0.0.1", "/api/v1/salidas-operativas", "test", "test", "test", "test");

    @Test void noPermiteContextoSinUot() {
        var result = service.solicitar(new E2Commands.Solicitar(null, null, null), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("E2_CONTEXTO_INVALIDO");
        verifyNoInteractions(port);
    }

    @Test void rechazaPaginacionMayorAlLimite() {
        var result = service.listar(new E2Commands.Listar(1L, null, null, 1, 101), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("E2_PAGINACION_INVALIDA");
        verifyNoInteractions(port);
    }

    @Test void preservaErroresDePermisoDeLaBaseDeDatos() {
        when(port.decidir(any(), any(), any()))
                .thenReturn(PersistenceResult.error("E2_PERMISO", "No tiene permiso para esta operación.", 403));
        var result = service.decidir(new E2Commands.Decidir(1L, null, 6L,
                new E2Commands.DecisionDatos("APROBADA", null)), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.estado()).isEqualTo(AppStatus.FORBIDDEN);
    }

    @Test void permiteEliminarBorradorSinMotivoYDelegaAutorizacionAlSql() {
        when(port.cancelar(any(), any(), any()))
                .thenReturn(PersistenceResult.ok("E2_ELIMINADA", "Borrador eliminado.", 200,
                        new E2Models.Operation(7L, null, "ELIMINADA")));
        var result = service.cancelar(new E2Commands.Cancelar(1L, null, 7L, null), identity, metadata);
        assertThat(result.exitoso()).isTrue();
        assertThat(result.datos().estado()).isEqualTo("ELIMINADA");
        verify(port).cancelar(argThat(c -> c.salidaId() == 7L && c.motivo() == null), eq(identity), eq(metadata));
    }

    @Test void solicitudEnviadaSinMotivoEsRechazadaPorBaseDeDatos() {
        when(port.cancelar(any(), any(), any()))
                .thenReturn(PersistenceResult.error("E2_MOTIVO_REQUERIDO", "Ingrese el motivo de cancelación.", 400));
        var result = service.cancelar(new E2Commands.Cancelar(1L, null, 8L, ""), identity, metadata);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("E2_MOTIVO_REQUERIDO");
        verify(port).cancelar(any(), eq(identity), eq(metadata));
    }
}
