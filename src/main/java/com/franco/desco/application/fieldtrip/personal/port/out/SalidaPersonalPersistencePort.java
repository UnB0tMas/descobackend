package com.franco.desco.application.fieldtrip.personal.port.out;

import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface SalidaPersonalPersistencePort {
    <T> PersistenceResult<T> consultar(SalidaPersonalQuery query,
            SessionIdentity identity, RequestMetadata metadata, Class<T> resultType);
}
