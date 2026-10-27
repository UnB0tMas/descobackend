package com.franco.desco.application.priceadjustment.port.out;

import com.franco.desco.application.priceadjustment.*;
import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.priceadjustment.*;
import java.util.*;

public interface PriceAdjustmentPersistencePort {
    PersistenceResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> create(PriceAdjustmentCommands.Create c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> cancel(PriceAdjustmentCommands.Cancel c, SessionIdentity i, RequestMetadata m);
}
