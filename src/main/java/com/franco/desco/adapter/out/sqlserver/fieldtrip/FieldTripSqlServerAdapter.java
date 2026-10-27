package com.franco.desco.adapter.out.sqlserver.fieldtrip;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.fieldtrip.*;
import com.franco.desco.application.fieldtrip.FieldTripCommands.*;
import com.franco.desco.application.fieldtrip.port.out.FieldTripPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.fieldtrip.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class FieldTripSqlServerAdapter
        extends JsonPaAdapterSupport
        implements FieldTripPersistencePort {

    public FieldTripSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<FieldTripModels.Summary>> list(FieldTripCommands.ListTrips c,SessionIdentity i,RequestMetadata m) {
        return page("campo.PA_SalidaCampo_Sel_Listado", c, i, m, FieldTripModels.Summary.class);
    }

    @Override
    public PersistenceResult<FieldTripModels.Detail> get(FieldTripCommands.GetTrip c,SessionIdentity i,RequestMetadata m) {
        return one("campo.PA_SalidaCampo_Sel_DetalleCompleto", c, i, m, FieldTripModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> program(FieldTripCommands.Program c,SessionIdentity i,RequestMetadata m) {
        return create("campo.PA_SalidaCampo_Ins_Programar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(FieldTripCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_SalidaCampo_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(FieldTripCommands.Cancel c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_SalidaCampo_Upd_Cancelar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> finish(FieldTripCommands.Finish c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_SalidaCampo_Upd_Finalizar", c, i, m);
    }

}
