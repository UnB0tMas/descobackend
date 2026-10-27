package com.franco.desco.application.liquidation.port.in;

import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.liquidation.LiquidationModels;

public interface LiquidationUseCase {
    AppResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> calculate(LiquidationCommands.Calculate command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> recalculate(LiquidationCommands.Recalculate command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> approve(LiquidationCommands.Approve command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(LiquidationCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
