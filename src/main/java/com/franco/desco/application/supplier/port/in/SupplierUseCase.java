package com.franco.desco.application.supplier.port.in;

import com.franco.desco.adapter.in.web.supplier.SupplierWebTypes;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.SessionIdentity;

public interface SupplierUseCase {
    AppResult<SupplierWebTypes.Page> list(Long uotId, String search, String type, boolean activeOnly,
                                           int page, int size, SessionIdentity identity);
    AppResult<SupplierWebTypes.Registered> register(SupplierWebTypes.Save data, SessionIdentity identity);
    AppResult<SupplierWebTypes.Registered> update(Long id, SupplierWebTypes.Save data, SessionIdentity identity);
    AppResult<SupplierWebTypes.Registered> setState(Long uotId, Long id, boolean enabled,
                                                    SessionIdentity identity);
}
