package com.franco.desco.application.e4.port.out;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E4PersistencePort {
    <T> PersistenceResult<T> execute(Execute command, SessionIdentity identity,
                                      RequestMetadata metadata, Class<T> resultType);
}
