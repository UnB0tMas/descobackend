package com.franco.desco.application.liquidation.port.out;

import com.franco.desco.application.liquidation.*;
import com.franco.desco.application.liquidation.LiquidationCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.liquidation.*;
import java.util.*;

public interface LiquidationPersistencePort {
    PersistenceResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> calculate(LiquidationCommands.Calculate c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> recalculate(LiquidationCommands.Recalculate c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> approve(LiquidationCommands.Approve c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(LiquidationCommands.Cancel c,SessionIdentity i,RequestMetadata m);
}
