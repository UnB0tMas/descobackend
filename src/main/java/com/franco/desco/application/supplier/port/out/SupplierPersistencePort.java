package com.franco.desco.application.supplier.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.adapter.in.web.supplier.SupplierWebTypes;

public interface SupplierPersistencePort {
    <T> PersistenceResult<T> execute(String action, Long uotId, Object data,
                                     SessionIdentity identity, Class<T> resultType);
}
