package com.franco.desco.adapter.out.sqlserver.salesoperation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.salesoperation.*;
import com.franco.desco.application.salesoperation.SalesOperationCommands.*;
import com.franco.desco.application.salesoperation.port.out.SalesOperationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.salesoperation.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class SalesOperationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements SalesOperationPersistencePort {

    public SalesOperationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<SalesOperationModels.Summary>> list(SalesOperationCommands.ListOperations c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_OperativoVenta_Sel_Listado", c, i, m, SalesOperationModels.Summary.class);
    }

    @Override
    public PersistenceResult<SalesOperationModels.Detail> get(SalesOperationCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("comercial.PA_OperativoVenta_Sel_DetalleCompleto", c, i, m, SalesOperationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(SalesOperationCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_OperativoVenta_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(SalesOperationCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_OperativoVenta_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> setZones(SalesOperationCommands.SetZones c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_OperativoVenta_Upd_Zonas", c, i, m);
    }

    @Override
    public PersistenceResult<Void> startReception(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_OperativoVenta_Upd_IniciarRecepcion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> close(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_OperativoVenta_Upd_Cerrar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(SalesOperationCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_OperativoVenta_Upd_Cancelar", c, i, m);
    }

}
