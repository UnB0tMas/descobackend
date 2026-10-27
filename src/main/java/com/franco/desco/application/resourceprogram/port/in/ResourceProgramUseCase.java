package com.franco.desco.application.resourceprogram.port.in;

import com.franco.desco.application.resourceprogram.ResourceProgramCommands;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.resourceprogram.ResourceProgramModels;

public interface ResourceProgramUseCase {

    AppResult<PageResult<ResourceProgramModels.Summary>> list(
            ResourceProgramCommands.ListResources command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<ResourceProgramModels.Detail> get(
            ResourceProgramCommands.Get command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<ResourceProgramModels.Availability> availability(
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Long> program(
            ResourceProgramCommands.Program command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> update(
            ResourceProgramCommands.Update command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> assign(
            ResourceProgramCommands.Assign command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> returnResource(
            ResourceProgramCommands.ReturnResource command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> consume(
            ResourceProgramCommands.Consume command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> cancel(
            ResourceProgramCommands.Cancel command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
