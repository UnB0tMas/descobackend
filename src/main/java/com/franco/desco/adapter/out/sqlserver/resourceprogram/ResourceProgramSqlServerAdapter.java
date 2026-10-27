package com.franco.desco.adapter.out.sqlserver.resourceprogram;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.resourceprogram.*;
import com.franco.desco.application.resourceprogram.ResourceProgramCommands.*;
import com.franco.desco.application.resourceprogram.port.out.ResourceProgramPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.resourceprogram.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class ResourceProgramSqlServerAdapter
        extends JsonPaAdapterSupport
        implements ResourceProgramPersistencePort {

    public ResourceProgramSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<ResourceProgramModels.Summary>> list(ResourceProgramCommands.ListResources c,SessionIdentity i,RequestMetadata m) {
        return page("logistica.PA_RecursoProgramado_Sel_Listado", c, i, m, ResourceProgramModels.Summary.class);
    }

    @Override
    public PersistenceResult<ResourceProgramModels.Detail> get(ResourceProgramCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("logistica.PA_RecursoProgramado_Sel_Detalle", c, i, m, ResourceProgramModels.Detail.class);
    }

    @Override
    public PersistenceResult<ResourceProgramModels.Availability> availability(SessionIdentity i,RequestMetadata m) {
        return one("logistica.PA_RecursoProgramado_Sel_Disponibilidad", null, i, m, ResourceProgramModels.Availability.class);
    }

    @Override
    public PersistenceResult<Long> program(ResourceProgramCommands.Program c,SessionIdentity i,RequestMetadata m) {
        return create("logistica.PA_RecursoProgramado_Ins_Programar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(ResourceProgramCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_RecursoProgramado_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> assign(ResourceProgramCommands.Assign c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_RecursoProgramado_Ins_Asignar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> returnResource(ResourceProgramCommands.ReturnResource c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_RecursoProgramado_Ins_Devolucion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> consume(ResourceProgramCommands.Consume c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_RecursoProgramado_Ins_Consumo", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(ResourceProgramCommands.Cancel c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_RecursoProgramado_Upd_Cancelar", c, i, m);
    }

}
