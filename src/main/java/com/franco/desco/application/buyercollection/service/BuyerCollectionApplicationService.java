package com.franco.desco.application.buyercollection.service;

import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.buyercollection.port.in.BuyerCollectionUseCase;
import com.franco.desco.application.buyercollection.port.out.BuyerCollectionPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.buyercollection.BuyerCollectionModels;

public final class BuyerCollectionApplicationService implements BuyerCollectionUseCase {
    private final BuyerCollectionPersistencePort persistence;
    public BuyerCollectionApplicationService(BuyerCollectionPersistencePort persistence){ this.persistence=persistence; }

    public AppResult<PageResult<BuyerCollectionModels.Summary>> list(ListCollections c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.list(c,i,m),"COBROS_LISTADOS","COBROS_NO_LISTADOS",AppStatus.BAD_REQUEST);
    }
    public AppResult<BuyerCollectionModels.Balance> balance(GetBalance c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.balance(c,i,m),"SALDO_COMPRADOR_OBTENIDO","SALDO_COMPRADOR_NO_DISPONIBLE",AppStatus.NOT_FOUND);
    }
    public AppResult<Long> create(CreateCollection c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.created(persistence.create(c,i,m),"COBRO_REGISTRADO","COBRO_NO_REGISTRADO");
    }
    public AppResult<Void> confirm(ConfirmCollection c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.confirm(c,i,m),"COBRO_CONFIRMADO","COBRO_NO_CONFIRMADO",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> cancel(CancelCollection c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.cancel(c,i,m),"COBRO_ANULADO","COBRO_NO_ANULADO",AppStatus.BAD_REQUEST);
    }
}
