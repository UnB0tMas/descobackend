package com.franco.desco.adapter.out.sqlserver.visit;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.visit.*;
import com.franco.desco.application.visit.VisitCommands.*;
import com.franco.desco.application.visit.port.out.VisitPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.visit.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class VisitSqlServerAdapter
        extends JsonPaAdapterSupport
        implements VisitPersistencePort {

    public VisitSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<VisitModels.Summary>> list(VisitCommands.ListVisits c,SessionIdentity i,RequestMetadata m) {
        return page("campo.PA_VisitaTecnica_Sel_Listado", c, i, m, VisitModels.Summary.class);
    }

    @Override
    public PersistenceResult<VisitModels.Detail> get(VisitCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("campo.PA_VisitaTecnica_Sel_DetalleCompleto", c, i, m, VisitModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> start(VisitCommands.Start c,SessionIdentity i,RequestMetadata m) {
        return create("campo.PA_VisitaTecnica_Ins_Iniciar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(VisitCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_VisitaTecnica_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> finish(VisitCommands.Finish c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_VisitaTecnica_Upd_Finalizar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> annul(VisitCommands.Annul c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_VisitaTecnica_Upd_Anular", c, i, m);
    }

}
