package com.franco.desco.application.campaignparticipant.port.out;

import com.franco.desco.application.campaignparticipant.*;
import com.franco.desco.application.campaignparticipant.CampaignParticipantCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.campaignparticipant.*;
import java.util.*;

public interface CampaignParticipantPersistencePort {
    PersistenceResult<PageResult<CampaignParticipantModels.Summary>> list(CampaignParticipantCommands.ListParticipants c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<CampaignParticipantModels.Detail> get(CampaignParticipantCommands.Get c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> include(CampaignParticipantCommands.Include c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> program(CampaignParticipantCommands.Program c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> remove(CampaignParticipantCommands.Remove c,SessionIdentity i,RequestMetadata m);
}
