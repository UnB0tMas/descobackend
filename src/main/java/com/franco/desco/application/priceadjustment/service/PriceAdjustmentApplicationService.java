package com.franco.desco.application.priceadjustment.service;

import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands;
import com.franco.desco.application.priceadjustment.port.in.PriceAdjustmentUseCase;
import com.franco.desco.application.priceadjustment.port.out.PriceAdjustmentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.priceadjustment.PriceAdjustmentModels;

public final class PriceAdjustmentApplicationService implements PriceAdjustmentUseCase {
    private final PriceAdjustmentPersistencePort persistence;

    public PriceAdjustmentApplicationService(PriceAdjustmentPersistencePort persistence) {
        this.persistence = persistence;
    }

    public AppResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c, i, m), "AJUSTES_LISTADOS", "AJUSTES_NO_LISTADOS", AppStatus.BAD_REQUEST);
    }

    public AppResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.impact(c, i, m), "AJUSTE_CONSULTADO", "AJUSTE_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }

    public AppResult<Long> create(PriceAdjustmentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.create(c, i, m), "AJUSTE_REGISTRADO", "AJUSTE_NO_REGISTRADO");
    }

    public AppResult<Void> cancel(PriceAdjustmentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.cancel(c, i, m), "AJUSTE_ANULADO", "AJUSTE_NO_ANULADO", AppStatus.BAD_REQUEST);
    }
}
