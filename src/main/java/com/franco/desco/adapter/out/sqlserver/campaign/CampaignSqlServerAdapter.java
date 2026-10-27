package com.franco.desco.adapter.out.sqlserver.campaign;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.campaign.*;
import com.franco.desco.application.campaign.CampaignCommands.*;
import com.franco.desco.application.campaign.port.out.CampaignPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.campaign.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CampaignSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CampaignPersistencePort {

    public CampaignSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CampaignModels.Summary>> list(CampaignCommands.ListCampaigns c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_CampaniaVenta_Sel_Listado", c, i, m, CampaignModels.Summary.class);
    }

    @Override
    public PersistenceResult<CampaignModels.Detail> get(CampaignCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("comercial.PA_CampaniaVenta_Sel_DetalleCompleto", c, i, m, CampaignModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CampaignCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_CampaniaVenta_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(CampaignCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CampaniaVenta_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> activate(CampaignCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CampaniaVenta_Upd_Activar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> close(CampaignCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CampaniaVenta_Upd_Cerrar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(CampaignCommands.Transition c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_CampaniaVenta_Upd_Cancelar", c, i, m);
    }

}
