package com.franco.desco.application.e5.port.out;

import com.franco.desco.application.e5.E5Commands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E5PersistencePort {
    <T> PersistenceResult<T> execute(E5Commands.Execute command, SessionIdentity identity,
                                    RequestMetadata metadata, Class<T> type);
}
