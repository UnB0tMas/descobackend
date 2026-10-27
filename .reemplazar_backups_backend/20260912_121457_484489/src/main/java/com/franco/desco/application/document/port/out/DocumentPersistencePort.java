package com.franco.desco.application.document.port.out;

import com.franco.desco.application.document.DocumentCommands.*;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.document.DocumentModels;

public interface DocumentPersistencePort {
    PersistenceResult<PageResult<DocumentModels.Summary>> list(ListDocuments command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<DocumentModels.Detail> get(GetDocument command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> register(RegisterDocument command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> retire(RetireDocument command, SessionIdentity identity, RequestMetadata metadata);
}
