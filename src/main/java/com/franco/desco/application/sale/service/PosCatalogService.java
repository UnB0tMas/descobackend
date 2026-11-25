package com.franco.desco.application.sale.service;

import com.franco.desco.application.sale.port.out.PosCatalogPort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.PosCatalogModels;
import org.springframework.stereotype.Service;

@Service
public class PosCatalogService {
    private final PosCatalogPort catalog;

    public PosCatalogService(PosCatalogPort catalog) {
        this.catalog = catalog;
    }

    public AppResult<PosCatalogModels.Catalog> list(SessionIdentity identity, Long uotId,
                                                    Long warehouseId, boolean internal) {
        return ApplicationResults.ok(catalog.list(identity, uotId, warehouseId, internal),
                "POS_CATALOGO_CONSULTADO", "POS_CATALOGO_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }
}
