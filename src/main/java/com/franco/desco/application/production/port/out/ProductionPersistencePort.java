package com.franco.desco.application.production.port.out;

import com.franco.desco.application.production.*;
import com.franco.desco.application.production.ProductionCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.production.*;
import java.util.*;

public interface ProductionPersistencePort {
    PersistenceResult<PageResult<ProductionModels.Summary>> list(ProductionCommands.ListProduction c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<ProductionModels.Detail> get(ProductionCommands.Get c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(ProductionCommands.Create c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(ProductionCommands.Update c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> confirm(ProductionCommands.Confirm c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> discard(ProductionCommands.Discard c,SessionIdentity i,RequestMetadata m);
}
