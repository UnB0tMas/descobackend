package com.franco.desco.application.uot.port.in;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotLifecycleCommands;
import com.franco.desco.domain.uot.UotLifecycleModels;

public interface UotLifecycleUseCase {
    AppResult<UotLifecycleModels.DeactivationImpact> impact(UotLifecycleCommands.Impact command, SessionIdentity identity);
    AppResult<UotLifecycleModels.ResourceTransfer> transfer(UotLifecycleCommands.TransferResources command, SessionIdentity identity);
    AppResult<Void> deactivate(UotLifecycleCommands.Deactivate command, SessionIdentity identity);
}
