package com.franco.desco.application.e4.port.in;

import com.franco.desco.application.e4.E4Commands.Execute;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;

public interface E4UseCase {
    <T> AppResult<T> execute(Execute command, SessionIdentity identity,
                             RequestMetadata metadata, Class<T> responseType);
}
