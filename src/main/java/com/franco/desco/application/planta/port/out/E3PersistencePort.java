package com.franco.desco.application.planta.port.out;

import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

/** Puerto transaccional de actuaciones individuales y lotes APAPPSS. */
public interface E3PersistencePort {
    <T> PersistenceResult<T> execute(Execute command, SessionIdentity identity,
                                     RequestMetadata metadata, Class<T> type);
}
