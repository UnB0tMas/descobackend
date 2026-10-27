package com.franco.desco.application.incident.port.in;

import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.incident.IncidentModels;

public interface IncidentUseCase {
    AppResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<IncidentModels.Detail> get(IncidentCommands.GetIncident command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(IncidentCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> review(IncidentCommands.Review command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> resolve(IncidentCommands.Resolve command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(IncidentCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
