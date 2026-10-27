package com.franco.desco.application.identity.port.out;

import com.franco.desco.application.identity.IdentityCommands.ResolveDocument;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.identity.IdentityModels.LocalResolution;
import com.franco.desco.domain.identity.IdentityModels.PersistOutcome;
import com.franco.desco.domain.identity.IdentityModels.ProviderResult;
import com.franco.desco.domain.identity.IdentityModels.Reservation;

public interface IdentityPersistencePort {

    PersistenceResult<LocalResolution> resolveLocal(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Reservation> reserveExternalQuery(
            ResolveDocument command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<PersistOutcome> registerExternalResult(
            ResolveDocument command,
            ProviderResult providerResult,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
