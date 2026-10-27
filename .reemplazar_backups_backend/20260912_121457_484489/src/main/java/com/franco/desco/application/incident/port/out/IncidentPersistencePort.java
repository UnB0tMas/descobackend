package com.franco.desco.application.incident.port.out;

import com.franco.desco.application.incident.IncidentCommands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.incident.IncidentModels;

public interface IncidentPersistencePort {
    PersistenceResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<IncidentModels.Detail> get(IncidentCommands.GetIncident command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(IncidentCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> review(IncidentCommands.Review command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> resolve(IncidentCommands.Resolve command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(IncidentCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
