package com.franco.desco.application.incident.service;

import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.incident.port.in.IncidentUseCase;
import com.franco.desco.application.incident.port.out.IncidentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.incident.IncidentModels;

public final class IncidentApplicationService implements IncidentUseCase {
    private final IncidentPersistencePort persistence;

    public IncidentApplicationService(IncidentPersistencePort persistence) {
        this.persistence = persistence;
    }

    public AppResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c, i, m), "INCIDENCIAS_LISTADAS", "INCIDENCIAS_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }

    public AppResult<IncidentModels.Detail> get(IncidentCommands.GetIncident c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.get(c, i, m), "INCIDENCIA_CONSULTADA", "INCIDENCIA_NO_DISPONIBLE", AppStatus.BAD_REQUEST);
    }

    public AppResult<Long> create(IncidentCommands.Create c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.create(c, i, m), "INCIDENCIA_REGISTRADA", "INCIDENCIA_NO_REGISTRADA");
    }

    public AppResult<Void> review(IncidentCommands.Review c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.review(c, i, m), "INCIDENCIA_EN_REVISION", "INCIDENCIA_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }

    public AppResult<Void> resolve(IncidentCommands.Resolve c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.resolve(c, i, m), "INCIDENCIA_RESUELTA", "INCIDENCIA_NO_RESUELTA", AppStatus.BAD_REQUEST);
    }

    public AppResult<Void> cancel(IncidentCommands.Cancel c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.cancel(c, i, m), "INCIDENCIA_ANULADA", "INCIDENCIA_NO_ANULADA", AppStatus.BAD_REQUEST);
    }
}
