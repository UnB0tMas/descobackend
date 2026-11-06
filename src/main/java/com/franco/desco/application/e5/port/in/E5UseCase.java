package com.franco.desco.application.e5.port.in;

import com.franco.desco.application.e5.E5Commands;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E5UseCase {
    <T> AppResult<T> execute(E5Commands.Execute command, SessionIdentity identity,
                            RequestMetadata metadata, Class<T> type);
}
