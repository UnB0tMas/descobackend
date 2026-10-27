package com.franco.desco.application.dashboard.port.in;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboard.DashboardModels;

public interface DashboardUseCase {

    AppResult<DashboardModels.Summary> summary(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
    );
}
