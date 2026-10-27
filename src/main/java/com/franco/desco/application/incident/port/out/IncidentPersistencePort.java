package com.franco.desco.application.incident.port.out;

import com.franco.desco.application.incident.*;
import com.franco.desco.application.incident.IncidentCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.incident.*;
import java.util.*;

public interface IncidentPersistencePort {
    PersistenceResult<PageResult<IncidentModels.Summary>> list(IncidentCommands.ListIncidents c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<IncidentModels.Detail> get(IncidentCommands.GetIncident c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> create(IncidentCommands.Create c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> review(IncidentCommands.Review c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> resolve(IncidentCommands.Resolve c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> cancel(IncidentCommands.Cancel c, SessionIdentity i, RequestMetadata m);
}
