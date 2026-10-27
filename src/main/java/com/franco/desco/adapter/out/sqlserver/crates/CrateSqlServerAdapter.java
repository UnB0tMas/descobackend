package com.franco.desco.adapter.out.sqlserver.crates;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.crates.*;
import com.franco.desco.application.crates.CrateCommands.*;
import com.franco.desco.application.crates.port.out.CratePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.crates.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CrateSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CratePersistencePort {

    public CrateSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CrateModels.Summary>> list(CrateCommands.ListCrates c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_Jabas_Sel_Listado", c, i, m, CrateModels.Summary.class);
    }

    @Override
    public PersistenceResult<CrateModels.Balance> balance(CrateCommands.Balance c,SessionIdentity i,RequestMetadata m) {
        return one("comercial.PA_Jabas_Sel_Saldo", c, i, m, CrateModels.Balance.class);
    }

    @Override
    public PersistenceResult<List<CrateModels.History>> history(CrateCommands.History c,SessionIdentity i,RequestMetadata m) {
        return list("comercial.PA_Jabas_Sel_Historial", c, i, m, CrateModels.History.class);
    }

    @Override
    public PersistenceResult<Long> receive(CrateCommands.Receive c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_Jabas_Ins_Recepcion", c, i, m);
    }

    @Override
    public PersistenceResult<Long> assign(CrateCommands.Assign c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_Jabas_Ins_Asignacion", c, i, m);
    }

    @Override
    public PersistenceResult<Long> returnCrates(CrateCommands.ReturnCrates c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_Jabas_Ins_Devolucion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> annul(CrateCommands.Annul c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_Jabas_Upd_AnularMovimiento", c, i, m);
    }

}
