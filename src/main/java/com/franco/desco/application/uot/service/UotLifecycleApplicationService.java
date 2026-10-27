package com.franco.desco.application.uot.service;

import com.franco.desco.application.shared.*;
import com.franco.desco.application.uot.UotLifecycleCommands;
import com.franco.desco.application.uot.port.in.UotLifecycleUseCase;
import com.franco.desco.application.uot.port.out.UotLifecyclePersistencePort;
import com.franco.desco.domain.uot.UotLifecycleModels;
import org.springframework.stereotype.Service;

@Service
public class UotLifecycleApplicationService implements UotLifecycleUseCase {
    private final UotLifecyclePersistencePort persistence;
    public UotLifecycleApplicationService(UotLifecyclePersistencePort persistence) { this.persistence = persistence; }
    public AppResult<UotLifecycleModels.DeactivationImpact> impact(UotLifecycleCommands.Impact c, SessionIdentity i) {
        return ApplicationResults.ok(persistence.impact(c,i), "UOT_IMPACTO_CONSULTADO", "UOT_IMPACTO_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }
    public AppResult<UotLifecycleModels.ResourceTransfer> transfer(UotLifecycleCommands.TransferResources c, SessionIdentity i) {
        return ApplicationResults.ok(persistence.transfer(c,i), "UOT_RECURSOS_TRANSFERIDOS", "UOT_RECURSOS_NO_TRANSFERIDOS", AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> deactivate(UotLifecycleCommands.Deactivate c, SessionIdentity i) {
        return ApplicationResults.ok(persistence.deactivate(c,i), "UOT_RETIRADA", "UOT_NO_RETIRADA", AppStatus.CONFLICT);
    }
}
