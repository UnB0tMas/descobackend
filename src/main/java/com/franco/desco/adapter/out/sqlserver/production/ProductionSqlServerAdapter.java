package com.franco.desco.adapter.out.sqlserver.production;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.production.*;
import com.franco.desco.application.production.ProductionCommands.*;
import com.franco.desco.application.production.port.out.ProductionPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.production.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class ProductionSqlServerAdapter
        extends JsonPaAdapterSupport
        implements ProductionPersistencePort {

    public ProductionSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<ProductionModels.Summary>> list(ProductionCommands.ListProduction c,SessionIdentity i,RequestMetadata m) {
        return page("prod.PA_DisponibilidadProduccion_Sel_Listado", c, i, m, ProductionModels.Summary.class);
    }

    @Override
    public PersistenceResult<ProductionModels.Detail> get(ProductionCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("prod.PA_DisponibilidadProduccion_Sel_Detalle", c, i, m, ProductionModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(ProductionCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("prod.PA_DisponibilidadProduccion_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(ProductionCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_DisponibilidadProduccion_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> confirm(ProductionCommands.Confirm c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_DisponibilidadProduccion_Upd_Confirmar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> discard(ProductionCommands.Discard c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_DisponibilidadProduccion_Upd_Descartar", c, i, m);
    }

}
