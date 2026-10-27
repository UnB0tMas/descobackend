package com.franco.desco.application.priceadjustment.port.in;

import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.priceadjustment.PriceAdjustmentModels;

public interface PriceAdjustmentUseCase {
    AppResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(PriceAdjustmentCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(PriceAdjustmentCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
