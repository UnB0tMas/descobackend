package com.franco.desco.application.productive.summary;

import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class GpResumenServiceTest {
    @Test
    void conservaUotActividadPeriodoYTipoAlConsultar() {
        GpResumenPort port = mock(GpResumenPort.class);
        GpResumenService service = new GpResumenService(port);
        SessionIdentity identity = new SessionIdentity(7L, UUID.randomUUID(), 1, "jwt");
        GpResumenDto expected = new GpResumenDto(2L, 3L, 0L, List.of(), List.of());
        when(port.consultar(identity, 2L, 10L, "90D", "EVALUACION")).thenReturn(expected);

        assertThat(service.consultar(identity, 2L, 10L, "90D", "EVALUACION")).isSameAs(expected);
        verify(port).consultar(identity, 2L, 10L, "90D", "EVALUACION");
        verifyNoMoreInteractions(port);
    }
}
