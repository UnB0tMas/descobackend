package com.franco.desco.adapter.out.sqlserver.priceadjustment;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.priceadjustment.*;
import com.franco.desco.application.priceadjustment.PriceAdjustmentCommands.*;
import com.franco.desco.application.priceadjustment.port.out.PriceAdjustmentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.priceadjustment.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class PriceAdjustmentSqlServerAdapter
        extends JsonPaAdapterSupport
        implements PriceAdjustmentPersistencePort {

    public PriceAdjustmentSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<PriceAdjustmentModels.Summary>> list(PriceAdjustmentCommands.ListAdjustments c, SessionIdentity i, RequestMetadata m) {
        return page("comercial.PA_AjustePrecioSocio_Sel_Listado", c, i, m, PriceAdjustmentModels.Summary.class);
    }

    @Override
    public PersistenceResult<PriceAdjustmentModels.Impact> impact(PriceAdjustmentCommands.GetImpact c, SessionIdentity i, RequestMetadata m) {
        return one("comercial.PA_AjustePrecioSocio_Sel_Impacto", c, i, m, PriceAdjustmentModels.Impact.class);
    }

    @Override
    public PersistenceResult<Long> create(PriceAdjustmentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        return create("comercial.PA_AjustePrecioSocio_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(PriceAdjustmentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        return mutate("comercial.PA_AjustePrecioSocio_Upd_Anular", c, i, m);
    }

}
