package com.franco.desco.application.document.port.in;

import com.franco.desco.application.document.DocumentCommands.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.document.DocumentModels;

public interface DocumentUseCase {
    AppResult<PageResult<DocumentModels.Summary>> list(ListDocuments command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<DocumentModels.Detail> get(GetDocument command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> register(RegisterDocument command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> retire(RetireDocument command, SessionIdentity identity, RequestMetadata metadata);
}
