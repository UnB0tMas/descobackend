package com.franco.desco.application.liquidation.service;

import com.franco.desco.application.liquidation.LiquidationCommands;
import com.franco.desco.application.liquidation.port.in.LiquidationUseCase;
import com.franco.desco.application.liquidation.port.out.LiquidationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.liquidation.LiquidationModels;

public final class LiquidationApplicationService implements LiquidationUseCase {
    private final LiquidationPersistencePort persistence;
    public LiquidationApplicationService(LiquidationPersistencePort persistence){this.persistence=persistence;}

    public AppResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.list(c,i,m),"LIQUIDACIONES_LISTADAS","LIQUIDACIONES_NO_LISTADAS",AppStatus.BAD_REQUEST);
    }
    public AppResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.get(c,i,m),"LIQUIDACION_CONSULTADA","LIQUIDACION_NO_DISPONIBLE",AppStatus.BAD_REQUEST);
    }
    public AppResult<Long> calculate(LiquidationCommands.Calculate c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.created(persistence.calculate(c,i,m),"LIQUIDACION_CALCULADA","LIQUIDACION_NO_CALCULADA");
    }
    public AppResult<Long> recalculate(LiquidationCommands.Recalculate c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.created(persistence.recalculate(c,i,m),"LIQUIDACION_RECALCULADA","LIQUIDACION_NO_RECALCULADA");
    }
    public AppResult<Void> approve(LiquidationCommands.Approve c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.approve(c,i,m),"LIQUIDACION_APROBADA","LIQUIDACION_NO_APROBADA",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> cancel(LiquidationCommands.Cancel c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.cancel(c,i,m),"LIQUIDACION_ANULADA","LIQUIDACION_NO_ANULADA",AppStatus.BAD_REQUEST);
    }
}
