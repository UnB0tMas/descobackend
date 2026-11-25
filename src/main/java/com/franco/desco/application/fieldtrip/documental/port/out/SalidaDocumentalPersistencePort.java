package com.franco.desco.application.fieldtrip.documental.port.out;

import com.franco.desco.application.fieldtrip.documental.SalidaDocumentalCommand;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface SalidaDocumentalPersistencePort {
    PersistenceResult<Object> ejecutar(SalidaDocumentalCommand command,
                                        SessionIdentity identity, RequestMetadata metadata);
}
