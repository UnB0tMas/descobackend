package com.franco.desco.application.uot.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotLifecycleCommands;
import com.franco.desco.domain.uot.UotLifecycleModels;

public interface UotLifecyclePersistencePort {
    PersistenceResult<UotLifecycleModels.DeactivationImpact> impact(UotLifecycleCommands.Impact command, SessionIdentity identity);
    PersistenceResult<UotLifecycleModels.ResourceTransfer> transfer(UotLifecycleCommands.TransferResources command, SessionIdentity identity);
    PersistenceResult<Void> deactivate(UotLifecycleCommands.Deactivate command, SessionIdentity identity);
}
