package com.franco.desco.application.resourceprogram.service;

import com.franco.desco.application.resourceprogram.ResourceProgramCommands;
import com.franco.desco.application.resourceprogram.port.in.ResourceProgramUseCase;
import com.franco.desco.application.resourceprogram.port.out.ResourceProgramPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.resourceprogram.ResourceProgramModels;

public final class ResourceProgramApplicationService
        implements ResourceProgramUseCase {

    private final ResourceProgramPersistencePort persistence;

    public ResourceProgramApplicationService(
            ResourceProgramPersistencePort persistence
    ) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<PageResult<ResourceProgramModels.Summary>> list(
            ResourceProgramCommands.ListResources command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.list(command, identity, metadata),
                "RECURSOS_LISTADOS",
                "RECURSOS_NO_LISTADOS",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<ResourceProgramModels.Detail> get(
            ResourceProgramCommands.Get command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.get(command, identity, metadata),
                "RECURSO_CONSULTADO",
                "RECURSO_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<ResourceProgramModels.Availability> availability(
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.availability(identity, metadata),
                "RECURSOS_DISPONIBLES",
                "DISPONIBILIDAD_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Long> program(
            ResourceProgramCommands.Program command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.program(command, identity, metadata),
                "RECURSO_PROGRAMADO",
                "RECURSO_NO_PROGRAMADO"
        );
    }

    @Override
    public AppResult<Void> update(
            ResourceProgramCommands.Update command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.update(command, identity, metadata),
                "RECURSO_ACTUALIZADO",
                "RECURSO_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> assign(
            ResourceProgramCommands.Assign command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.assign(command, identity, metadata),
                "RECURSO_ASIGNADO",
                "RECURSO_NO_ASIGNADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> returnResource(
            ResourceProgramCommands.ReturnResource command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.returnResource(command, identity, metadata),
                "RECURSO_DEVUELTO",
                "RECURSO_NO_DEVUELTO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> consume(
            ResourceProgramCommands.Consume command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.consume(command, identity, metadata),
                "CONSUMO_REGISTRADO",
                "CONSUMO_NO_REGISTRADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> cancel(
            ResourceProgramCommands.Cancel command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.cancel(command, identity, metadata),
                "RECURSO_CANCELADO",
                "RECURSO_NO_CANCELADO",
                AppStatus.BAD_REQUEST
        );
    }
}
