package com.franco.desco.adapter.out.sqlserver.liquidation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.liquidation.*;
import com.franco.desco.application.liquidation.LiquidationCommands.*;
import com.franco.desco.application.liquidation.port.out.LiquidationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.liquidation.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class LiquidationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements LiquidationPersistencePort {

    public LiquidationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<LiquidationModels.Summary>> list(LiquidationCommands.ListLiquidations c,SessionIdentity i,RequestMetadata m) {
        return page("finanzas.PA_LiquidacionSocio_Sel_Listado", c, i, m, LiquidationModels.Summary.class);
    }

    @Override
    public PersistenceResult<LiquidationModels.Detail> get(LiquidationCommands.GetLiquidation c,SessionIdentity i,RequestMetadata m) {
        return one("finanzas.PA_LiquidacionSocio_Sel_Detalle", c, i, m, LiquidationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> calculate(LiquidationCommands.Calculate c,SessionIdentity i,RequestMetadata m) {
        return create("finanzas.PA_LiquidacionSocio_Ins_Calcular", c, i, m);
    }

    @Override
    public PersistenceResult<Long> recalculate(LiquidationCommands.Recalculate c,SessionIdentity i,RequestMetadata m) {
        return create("finanzas.PA_LiquidacionSocio_Ins_RecalcularVersion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> approve(LiquidationCommands.Approve c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_LiquidacionSocio_Upd_Aprobar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(LiquidationCommands.Cancel c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_LiquidacionSocio_Upd_Anular", c, i, m);
    }

}
