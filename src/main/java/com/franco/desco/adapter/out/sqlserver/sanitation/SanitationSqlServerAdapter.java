package com.franco.desco.adapter.out.sqlserver.sanitation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.sanitation.*;
import com.franco.desco.application.sanitation.SanitationCommands.*;
import com.franco.desco.application.sanitation.port.out.SanitationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.sanitation.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class SanitationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements SanitationPersistencePort {

    public SanitationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<SanitationModels.Summary>> list(SanitationCommands.ListCases c,SessionIdentity i,RequestMetadata m) {
        return page("sanidad.PA_CasoFitosanitario_Sel_Listado", c, i, m, SanitationModels.Summary.class);
    }

    @Override
    public PersistenceResult<SanitationModels.Detail> get(SanitationCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("sanidad.PA_CasoFitosanitario_Sel_DetalleCompleto", c, i, m, SanitationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(SanitationCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("sanidad.PA_CasoFitosanitario_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(SanitationCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("sanidad.PA_CasoFitosanitario_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> changeState(SanitationCommands.ChangeState c,SessionIdentity i,RequestMetadata m) {
        return mutate("sanidad.PA_CasoFitosanitario_Upd_Estado", c, i, m);
    }

    @Override
    public PersistenceResult<Void> close(SanitationCommands.Close c,SessionIdentity i,RequestMetadata m) {
        return mutate("sanidad.PA_CasoFitosanitario_Upd_Cerrar", c, i, m);
    }

    @Override
    public PersistenceResult<Long> addTreatment(SanitationCommands.Treatment c,SessionIdentity i,RequestMetadata m) {
        return create("sanidad.PA_TratamientoFitosanitario_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Long> addFollowUp(SanitationCommands.FollowUp c,SessionIdentity i,RequestMetadata m) {
        return create("sanidad.PA_SeguimientoFitosanitario_Ins_Registro", c, i, m);
    }

}
