package com.franco.desco.application.document.service;

import com.franco.desco.application.document.DocumentCommands.*;
import com.franco.desco.application.document.port.in.DocumentUseCase;
import com.franco.desco.application.document.port.out.DocumentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.document.DocumentModels;

public final class DocumentApplicationService implements DocumentUseCase {

    private final DocumentPersistencePort persistence;

    public DocumentApplicationService(DocumentPersistencePort persistence) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<PageResult<DocumentModels.Summary>> list(ListDocuments command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.list(command, identity, metadata), "ARCHIVOS_LISTADOS", "ARCHIVOS_NO_LISTADOS", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<DocumentModels.Detail> get(GetDocument command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.get(command, identity, metadata), "ARCHIVO_OBTENIDO", "ARCHIVO_NO_DISPONIBLE", AppStatus.NOT_FOUND);
    }

    @Override
    public AppResult<Long> register(RegisterDocument command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.created(persistence.register(command, identity, metadata), "ARCHIVO_REGISTRADO", "ARCHIVO_NO_REGISTRADO");
    }

    @Override
    public AppResult<Void> retire(RetireDocument command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.retire(command, identity, metadata), "ARCHIVO_RETIRADO", "ARCHIVO_NO_RETIRADO", AppStatus.BAD_REQUEST);
    }
}
