package com.franco.desco.application.priceadjustment.port.out;

import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.priceadjustment.PriceAdjustmentModels;

public interface PriceAdjustmentPersistencePort {
    PersistenceResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(PriceAdjustmentCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(PriceAdjustmentCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
