package com.franco.desco.adapter.out.sqlserver.incident;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.incident.*;
import com.franco.desco.application.incident.IncidentCommands.*;
import com.franco.desco.application.incident.port.out.IncidentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.incident.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class IncidentSqlServerAdapter
        extends JsonPaAdapterSupport
        implements IncidentPersistencePort {

    public IncidentSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents c, SessionIdentity i, RequestMetadata m) {
        return page("comercial.PA_IncidenciaOperativa_Sel_Listado", c, i, m, IncidentModels.Summary.class);
    }

    @Override
    public PersistenceResult<IncidentModels.Detail> get(IncidentCommands.GetIncident c, SessionIdentity i, RequestMetadata m) {
        return one("comercial.PA_IncidenciaOperativa_Sel_Detalle", c, i, m, IncidentModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(IncidentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        return create("comercial.PA_IncidenciaOperativa_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> review(IncidentCommands.Review c, SessionIdentity i, RequestMetadata m) {
        return mutate("comercial.PA_IncidenciaOperativa_Upd_Revision", c, i, m);
    }

    @Override
    public PersistenceResult<Void> resolve(IncidentCommands.Resolve c, SessionIdentity i, RequestMetadata m) {
        return mutate("comercial.PA_IncidenciaOperativa_Upd_Resolver", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(IncidentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        return mutate("comercial.PA_IncidenciaOperativa_Upd_Anular", c, i, m);
    }

}
