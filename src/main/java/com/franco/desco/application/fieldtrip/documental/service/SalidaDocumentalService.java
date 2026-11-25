package com.franco.desco.application.fieldtrip.documental.service;

import com.franco.desco.application.correspondence.CorrespondenceService;
import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.fieldtrip.documental.port.in.SalidaDocumentalUseCase;
import com.franco.desco.application.fieldtrip.documental.port.out.SalidaDocumentalPersistencePort;
import com.franco.desco.application.shared.*;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Set;

@Service
public final class SalidaDocumentalService implements SalidaDocumentalUseCase {
    private static final Set<String> DOCUMENT_ACTIONS = Set.of(
            "SOLICITAR", "ENVIAR_BORRADOR", "CORREGIR", "DECIDIR", "CANCELAR");
    private final SalidaDocumentalPersistencePort repository;
    private final CorrespondenceService correspondence;

    public SalidaDocumentalService(SalidaDocumentalPersistencePort repository,
                                   CorrespondenceService correspondence) {
        this.repository = repository;
        this.correspondence = correspondence;
    }

    @Override
    public AppResult<Object> ejecutar(SalidaDocumentalCommand command,
                                       SessionIdentity identity, RequestMetadata metadata) {
        if (command == null || command.uotId() == null || command.uotId() <= 0)
            return AppResult.error(AppStatus.BAD_REQUEST, "SALIDA_DOC_UOT", "Seleccione una unidad territorial.");
        if (identity == null || identity.sesionPublicaId() == null)
            return AppResult.error(AppStatus.UNAUTHORIZED, "SALIDA_DOC_SESION", "Inicie sesión nuevamente.");
        if (command.accion() == null || command.accion().isBlank())
            return AppResult.error(AppStatus.BAD_REQUEST, "SALIDA_DOC_ACCION", "Seleccione una acción válida.");
        PersistenceResult<Object> result = repository.ejecutar(command, identity, metadata);
        // El PA ya confirmó el documento y sus destinatarios dentro de la transacción.
        // Un reintento idempotente solo refresca el hilo: no genera otro mensaje.
        if (result.exitoso() && DOCUMENT_ACTIONS.contains(command.accion())
                && result.datos() instanceof Map<?, ?> document
                && document.get("documentoId") instanceof Number id && id.longValue() > 0) {
            correspondence.notifyDocumentChanged(id.longValue(), command.uotId(),
                    "ENVIAR", identity, metadata);
        }
        AppStatus status = switch (result.httpSugerido()) {
            case 200, 201 -> AppStatus.OK;
            case 401 -> AppStatus.UNAUTHORIZED;
            case 403 -> AppStatus.FORBIDDEN;
            case 404 -> AppStatus.NOT_FOUND;
            case 409 -> AppStatus.CONFLICT;
            case 503 -> AppStatus.SERVICE_UNAVAILABLE;
            case 500 -> AppStatus.INTERNAL_ERROR;
            default -> AppStatus.BAD_REQUEST;
        };
        return new AppResult<>(result.exitoso(), result.codigo(), result.mensaje(), result.datos(), status);
    }
}
