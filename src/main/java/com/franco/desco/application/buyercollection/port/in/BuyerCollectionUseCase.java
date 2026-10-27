package com.franco.desco.application.buyercollection.port.in;

import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.buyercollection.BuyerCollectionModels;

public interface BuyerCollectionUseCase {
    AppResult<PageResult<BuyerCollectionModels.Summary>> list(ListCollections command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<BuyerCollectionModels.Balance> balance(GetBalance command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(CreateCollection command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> confirm(ConfirmCollection command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(CancelCollection command, SessionIdentity identity, RequestMetadata metadata);
}
