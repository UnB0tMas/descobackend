package com.franco.desco.application.fieldtrip.documental.service;

import com.franco.desco.adapter.out.sqlserver.correspondence.CorrespondenceSqlServerRepository;
import com.franco.desco.application.correspondence.CorrespondenceEvents;
import com.franco.desco.application.correspondence.CorrespondenceService;
import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.fieldtrip.documental.port.out.SalidaDocumentalPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.Mockito.*;

class SalidaDocumentalServiceTest {
    private final SalidaDocumentalPersistencePort salidas = mock(SalidaDocumentalPersistencePort.class);
    private final CorrespondenceSqlServerRepository documentos = mock(CorrespondenceSqlServerRepository.class);
    private final CorrespondenceEvents events = mock(CorrespondenceEvents.class);
    private final SalidaDocumentalService service = new SalidaDocumentalService(salidas,
            new CorrespondenceService(documentos, events));
    private final SessionIdentity identity = new SessionIdentity(1L, UUID.randomUUID(), 1, "test");
    private final RequestMetadata metadata = new RequestMetadata(UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "127.0.0.1", "/api/v1/salidas-tecnicas", "test", "test", "test", "test");

    @Test
    void correccionNotificaAlAdministradorInclusoSiEsElEmisor() {
        var command = new SalidaDocumentalCommand("CORREGIR", 2L, 3L, null, Map.of());
        when(salidas.ejecutar(command, identity, metadata)).thenReturn(
                PersistenceResult.ok("SALIDA_DOC_OK", "Guardado", 200, Map.of("documentoId", 5L)));
        when(documentos.execute("AVISOS", Map.of("documentoId", 5L, "uotId", 2L, "tipoAviso", "ENVIAR"),
                identity, metadata, Object.class)).thenReturn(AppResult.ok("DOCS_AVISOS_OK", "Consultado",
                List.of(Map.of("usuarioId", 1L), Map.of("usuarioId", 1L), Map.of("usuarioId", 7L))));
        assertTrue(service.ejecutar(command, identity, metadata).exitoso());
        var orden = inOrder(salidas, documentos, events);
        orden.verify(salidas).ejecutar(command, identity, metadata);
        orden.verify(documentos).execute("AVISOS", Map.of("documentoId", 5L, "uotId", 2L, "tipoAviso", "ENVIAR"),
                identity, metadata, Object.class);
        orden.verify(events).changed(1L);
        orden.verify(events).changed(7L);
        verifyNoMoreInteractions(events);
    }

    @Test
    void lecturaYErrorNoPublicanAvisos() {
        var lectura = new SalidaDocumentalCommand("VINCULO", 2L, 3L, null, null);
        var error = new SalidaDocumentalCommand("CORREGIR", 2L, 3L, null, Map.of());
        when(salidas.ejecutar(lectura, identity, metadata)).thenReturn(
                PersistenceResult.ok("SALIDA_DOC_OK", "Consultado", 200, Map.of("documentoId", 5L)));
        when(salidas.ejecutar(error, identity, metadata)).thenReturn(
                PersistenceResult.error("SALIDA_DOC_VALIDACION", "No disponible", 409));
        assertTrue(service.ejecutar(lectura, identity, metadata).exitoso());
        assertFalse(service.ejecutar(error, identity, metadata).exitoso());
        verifyNoInteractions(documentos, events);
    }

    @Test
    void errorDelCanalNoRevierteElGuardadoConfirmado() {
        var command = new SalidaDocumentalCommand("CORREGIR", 2L, 3L, null, Map.of());
        when(salidas.ejecutar(command, identity, metadata)).thenReturn(
                PersistenceResult.ok("SALIDA_DOC_OK", "Guardado", 200, Map.of("documentoId", 5L)));
        when(documentos.execute("AVISOS", Map.of("documentoId", 5L, "uotId", 2L, "tipoAviso", "ENVIAR"),
                identity, metadata, Object.class)).thenThrow(new IllegalStateException("test"));
        assertTrue(service.ejecutar(command, identity, metadata).exitoso());
        verifyNoInteractions(events);
    }
}
