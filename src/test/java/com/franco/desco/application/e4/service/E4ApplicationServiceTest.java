package com.franco.desco.application.e4.service;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.e4.port.out.E4PersistencePort;
import com.franco.desco.application.shared.*;
import org.junit.jupiter.api.Test;
import java.util.List;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

class E4ApplicationServiceTest {
    private final E4PersistencePort port = mock(E4PersistencePort.class);
    private final E4ApplicationService service = new E4ApplicationService(port);
    private final SessionIdentity identity = new SessionIdentity(10L, UUID.randomUUID(), 1, "test");
    private final RequestMetadata metadata = new RequestMetadata(UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "127.0.0.1", "/api/v1/apappss/acopio-e4", "test", "test", "test", "test");

    @Test void exigeIdentificadorDeContexto() {
        AppResult<String> result = service.execute(new Execute("SOCIOS",null,null,null,null,null,null),
                identity,metadata,String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("E4_CONTEXTO_INVALIDO");
        verifyNoInteractions(port);
    }

    @Test void soloPermiteAccionesComercialesDefinidas() {
        AppResult<String> result = service.execute(new Execute("BORRAR",1L,null,null,null,null,null),
                identity,metadata,String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("E4_OPERACION_INVALIDA");
        verifyNoInteractions(port);
    }

    @Test void propagaDenegacionDePermiso() {
        when(port.execute(any(),any(),any(),eq(String.class)))
                .thenReturn(PersistenceResult.error("E4_ERROR","No dispone del permiso solicitado.",403));
        AppResult<String> result = service.execute(new Execute("INCLUIR_SOCIOS",1L,null,null,null,null,
                        List.of(3L,5L)),identity,metadata,String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.estado()).isEqualTo(AppStatus.FORBIDDEN);
    }
}
