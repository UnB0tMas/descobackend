package com.franco.desco.application.fieldtrip.port.out;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.*;

public interface E2PersistencePort {
    <T> PersistenceResult<T> execute(E2Commands.Execute command, SessionIdentity identity,
                                    RequestMetadata metadata, Class<T> resultType);
}
