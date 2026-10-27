package com.franco.desco.application.dashboard.port.out;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboard.DashboardModels;

public interface DashboardPersistencePort {

    PersistenceResult<DashboardModels.Summary> summary(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
    );
}
