package com.franco.desco.application.liquidation.port.out;

import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.liquidation.LiquidationModels;

public interface LiquidationPersistencePort {
    PersistenceResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> calculate(LiquidationCommands.Calculate command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> recalculate(LiquidationCommands.Recalculate command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> approve(LiquidationCommands.Approve command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(LiquidationCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
