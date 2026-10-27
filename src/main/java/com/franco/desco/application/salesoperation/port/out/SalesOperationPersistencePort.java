package com.franco.desco.application.salesoperation.port.out;

import com.franco.desco.application.salesoperation.*;
import com.franco.desco.application.salesoperation.SalesOperationCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.salesoperation.*;
import java.util.*;

public interface SalesOperationPersistencePort {
    PersistenceResult<PageResult<SalesOperationModels.Summary>> list(SalesOperationCommands.ListOperations c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<SalesOperationModels.Detail> get(SalesOperationCommands.Get c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(SalesOperationCommands.Create c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(SalesOperationCommands.Update c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> setZones(SalesOperationCommands.SetZones c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> startReception(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> close(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m);
}
