package com.franco.desco.adapter.out.sqlserver.pricing;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.pricing.*;
import com.franco.desco.application.pricing.PricingCommands.*;
import com.franco.desco.application.pricing.port.out.PricingPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.pricing.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class PricingSqlServerAdapter
        extends JsonPaAdapterSupport
        implements PricingPersistencePort {

    public PricingSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<PricingModels.Condition>> conditions(PricingCommands.ListConditions c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_CondicionComercial_Sel_Listado", c, i, m, PricingModels.Condition.class);
    }

    @Override
    public PersistenceResult<Long> createCondition(PricingCommands.CreateCondition c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_CondicionComercial_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateCondition(PricingCommands.UpdateCondition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CondicionComercial_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> disableCondition(PricingCommands.DisableCondition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CondicionComercial_Upd_Deshabilitar", c, i, m);
    }

    @Override
    public PersistenceResult<PageResult<PricingModels.Price>> prices(PricingCommands.ListPrices c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_PrecioComercial_Sel_Listado", c, i, m, PricingModels.Price.class);
    }

    @Override
    public PersistenceResult<Long> createPrice(PricingCommands.CreatePrice c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_PrecioComercial_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Long> versionPrice(PricingCommands.VersionPrice c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_PrecioComercial_Ins_Version", c, i, m);
    }

    @Override
    public PersistenceResult<List<PricingModels.PriceVersion>> history(PricingCommands.PriceHistory c,SessionIdentity i,RequestMetadata m) {
        return list("comercial.PA_PrecioComercial_Sel_Historial", c, i, m, PricingModels.PriceVersion.class);
    }

}
