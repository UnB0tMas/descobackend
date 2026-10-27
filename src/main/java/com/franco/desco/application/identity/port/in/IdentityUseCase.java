package com.franco.desco.application.identity.port.in;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.ResolutionResult;

public interface IdentityUseCase {

    AppResult<ResolutionResult> resolve(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
