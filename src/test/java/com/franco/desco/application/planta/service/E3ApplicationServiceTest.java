package com.franco.desco.application.planta.service;

import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.planta.port.out.E3PersistencePort;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.planta.E3Models;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class E3ApplicationServiceTest {
    private final E3PersistencePort persistence = mock(E3PersistencePort.class);
    private final E3ApplicationService service = new E3ApplicationService(persistence);
    private final SessionIdentity identity = new SessionIdentity(1L, null, 1, "test");
    private final RequestMetadata metadata = new RequestMetadata(null, null, null, null, null, null, null, null, null);

    @Test
    void rechazaContextoSinConvenioSinAccederABase() {
        var command = new Execute("LOTE", 3L, null, 9L, null, null, null, null, null, null, null);
        var result = service.execute(command, identity, metadata, E3Models.Batch.class);
        assertThat(result.estado()).isEqualTo(AppStatus.BAD_REQUEST);
        verifyNoInteractions(persistence);
    }

    @Test
    void rechazaPaginacionFueraDelRango() {
        var command = new Execute("LISTAR", 3L, 4L, 9L, null, null, null, null, 1, 101, null);
        var result = service.execute(command, identity, metadata, E3Models.Page.class);
        assertThat(result.estado()).isEqualTo(AppStatus.BAD_REQUEST);
        verifyNoInteractions(persistence);
    }

    @Test
    void conservaErrorDeSeguridadDelProcedimiento() {
        var command = new Execute("VER", 3L, 4L, 9L, 5L, null, null, null, null, null, null);
        when(persistence.execute(eq(command), eq(identity), eq(metadata), eq(E3Models.Detail.class)))
            .thenReturn(PersistenceResult.error("E3_ERROR", "No autorizado en el convenio.", 403));
        var result = service.execute(command, identity, metadata, E3Models.Detail.class);
        assertThat(result.estado()).isEqualTo(AppStatus.FORBIDDEN);
    }

    @Test
    void seguimientoMasivoConservaLaRespuestaTipada() {
        var command = new Execute("MASIVO", 3L, 4L, 9L, null,
                null, null, null, null, null, null);
        var expected = new E3Models.BatchFollowUp(20);
        when(persistence.execute(eq(command), eq(identity), eq(metadata), eq(E3Models.BatchFollowUp.class)))
                .thenReturn(PersistenceResult.ok("E3_OK", "Registrado", 200, expected));
        var result = service.execute(command, identity, metadata, E3Models.BatchFollowUp.class);
        assertThat(result.datos()).isEqualTo(expected);
    }
}
