package com.franco.desco.application.dashboardbi;

import com.franco.desco.domain.dashboardbi.DashboardBiModels;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class DashboardBiServiceTest {
    private final DashboardBiPort port = mock(DashboardBiPort.class);
    private final DashboardBiService service = new DashboardBiService(port);

    @Test
    void rechazaTabsAjenoAlDashboard() {
        var result = service.load(new DashboardBiModels.Filter("APAPPSS", null, null, null, null), null, null);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.codigo()).isEqualTo("BI_TAB_INVALIDO");
        verifyNoInteractions(port);
    }

    @Test
    void rechazaPeriodosInvertidos() {
        var result = service.load(new DashboardBiModels.Filter("POS",
                LocalDate.of(2026, 1, 31), LocalDate.of(2026, 1, 1), null, null), null, null);
        assertThat(result.exitoso()).isFalse();
        verifyNoInteractions(port);
    }

    @Test
    void rechazaPeriodosSuperioresA366Dias() {
        var result = service.load(new DashboardBiModels.Filter("RECURSOS",
                LocalDate.of(2024, 1, 1), LocalDate.of(2026, 1, 1), null, null), null, null);
        assertThat(result.exitoso()).isFalse();
        verifyNoInteractions(port);
    }

    @Test
    void rechazaIdentificadoresNoValidos() {
        var result = service.load(new DashboardBiModels.Filter("DOCUMENTOS",
                LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 31), null, -1L), null, null);
        assertThat(result.exitoso()).isFalse();
        verifyNoInteractions(port);
    }
}
