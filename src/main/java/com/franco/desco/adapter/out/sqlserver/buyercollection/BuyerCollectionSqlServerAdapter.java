package com.franco.desco.adapter.out.sqlserver.buyercollection;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.buyercollection.*;
import com.franco.desco.application.buyercollection.BuyerCollectionCommands.*;
import com.franco.desco.application.buyercollection.port.out.BuyerCollectionPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.buyercollection.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class BuyerCollectionSqlServerAdapter
        extends JsonPaAdapterSupport
        implements BuyerCollectionPersistencePort {

    public BuyerCollectionSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<BuyerCollectionModels.Summary>> list(ListCollections c,SessionIdentity i,RequestMetadata m) {
        return page("finanzas.PA_CobroComprador_Sel_Listado", c, i, m, BuyerCollectionModels.Summary.class);
    }

    @Override
    public PersistenceResult<BuyerCollectionModels.Balance> balance(GetBalance c,SessionIdentity i,RequestMetadata m) {
        return one("finanzas.PA_CobroComprador_Sel_SaldoCampania", c, i, m, BuyerCollectionModels.Balance.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateCollection c,SessionIdentity i,RequestMetadata m) {
        return create("finanzas.PA_CobroComprador_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> confirm(ConfirmCollection c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_CobroComprador_Upd_Confirmar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(CancelCollection c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_CobroComprador_Upd_Anular", c, i, m);
    }

}
