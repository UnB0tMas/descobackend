package com.franco.desco.application.report.service;

import com.franco.desco.application.report.port.out.TemporaryReportPort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.infrastructure.storage.LocalBinaryStorage;
import com.franco.desco.infrastructure.storage.LocalFileDeleteQueue;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class TemporaryReportServiceTest {
    private final TemporaryReportPort reports = mock(TemporaryReportPort.class);
    private final LocalBinaryStorage storage = mock(LocalBinaryStorage.class);
    private final LocalFileDeleteQueue queue = mock(LocalFileDeleteQueue.class);
    private final TemporaryReportService service = new TemporaryReportService(reports, storage, queue);
    private final SessionIdentity identity = mock(SessionIdentity.class);
    private final RequestMetadata metadata = mock(RequestMetadata.class);

    @Test
    void eliminaArchivoYRegistroSoloCuandoConfirmacionEsCorrecta() throws Exception {
        when(reports.confirm("EXCEL", 25, identity, metadata))
                .thenReturn(PersistenceResult.ok("OK", "Confirmado", 200, "exports/25.xlsx"));

        PersistenceResult<Void> result = service.confirm("EXCEL", 25, identity, metadata);

        assertThat(result.exitoso()).isTrue();
        verify(queue).enqueue("exports/25.xlsx");
        verify(storage).delete("exports/25.xlsx");
    }

    @Test
    void noEliminaArchivoSiNoSeAutorizaLaConfirmacion() throws Exception {
        when(reports.confirm("ESPECIAL", 16, identity, metadata))
                .thenReturn(PersistenceResult.error("SIN_PERMISO", "No tiene acceso.", 403));

        PersistenceResult<Void> result = service.confirm("ESPECIAL", 16, identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(403);
        verifyNoInteractions(queue, storage);
    }

    @Test
    void conservaElReintentoSiFallaLaEliminacionFisica() throws Exception {
        when(reports.confirm("ESPECIAL", 7, identity, metadata))
                .thenReturn(PersistenceResult.ok("OK", "Confirmado", 200, "reports-special/7.pdf"));
        doThrow(new java.io.IOException("locked")).when(storage).delete("reports-special/7.pdf");

        PersistenceResult<Void> result = service.confirm("ESPECIAL", 7, identity, metadata);

        assertThat(result.exitoso()).isTrue();
        verify(queue).enqueue("reports-special/7.pdf");
    }
}
