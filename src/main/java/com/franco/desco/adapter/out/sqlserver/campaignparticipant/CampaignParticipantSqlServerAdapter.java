package com.franco.desco.adapter.out.sqlserver.campaignparticipant;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.campaignparticipant.*;
import com.franco.desco.application.campaignparticipant.CampaignParticipantCommands.*;
import com.franco.desco.application.campaignparticipant.port.out.CampaignParticipantPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.campaignparticipant.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CampaignParticipantSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CampaignParticipantPersistencePort {

    public CampaignParticipantSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CampaignParticipantModels.Summary>> list(CampaignParticipantCommands.ListParticipants c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_ParticipacionCampaniaSocio_Sel_Listado", c, i, m, CampaignParticipantModels.Summary.class);
    }

    @Override
    public PersistenceResult<CampaignParticipantModels.Detail> get(CampaignParticipantCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("comercial.PA_ParticipacionCampaniaSocio_Sel_Detalle", c, i, m, CampaignParticipantModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> include(CampaignParticipantCommands.Include c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_ParticipacionCampaniaSocio_Ins_Incluir", c, i, m);
    }

    @Override
    public PersistenceResult<Long> program(CampaignParticipantCommands.Program c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_ParticipacionCampaniaSocio_Ins_ProgramarOperativo", c, i, m);
    }

    @Override
    public PersistenceResult<Void> remove(CampaignParticipantCommands.Remove c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_ParticipacionCampaniaSocio_Upd_Retirar", c, i, m);
    }

}
