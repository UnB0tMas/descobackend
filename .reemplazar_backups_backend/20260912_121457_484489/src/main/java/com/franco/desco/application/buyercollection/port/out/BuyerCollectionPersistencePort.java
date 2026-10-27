package com.franco.desco.application.buyercollection.port.out;

import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.buyercollection.BuyerCollectionModels;

public interface BuyerCollectionPersistencePort {
    PersistenceResult<PageResult<BuyerCollectionModels.Summary>> list(ListCollections command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<BuyerCollectionModels.Balance> balance(GetBalance command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(CreateCollection command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> confirm(ConfirmCollection command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(CancelCollection command, SessionIdentity identity, RequestMetadata metadata);
}
