package com.franco.desco.application.fieldtrip.documental.port.in;

import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface SalidaDocumentalUseCase {
    AppResult<Object> ejecutar(SalidaDocumentalCommand command,
                               SessionIdentity identity, RequestMetadata metadata);
}
