package com.franco.desco.application.buyercollection.port.out;

import com.franco.desco.application.buyercollection.*;
import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.buyercollection.*;
import java.util.*;

public interface BuyerCollectionPersistencePort {
    PersistenceResult<PageResult<BuyerCollectionModels.Summary>> list(ListCollections c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<BuyerCollectionModels.Balance> balance(GetBalance c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateCollection c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> confirm(ConfirmCollection c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(CancelCollection c,SessionIdentity i,RequestMetadata m);
}
