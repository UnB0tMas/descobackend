package com.franco.desco.application.sale.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.PosCatalogModels;

public interface PosCatalogPort {
    PersistenceResult<PosCatalogModels.Catalog> list(SessionIdentity identity, Long uotId,
                                                     Long warehouseId, boolean internal);
}
