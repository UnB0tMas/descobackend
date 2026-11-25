package com.franco.desco.application.dashboardbi;

import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboardbi.DashboardBiModels;

public interface DashboardBiPort {
    PersistenceResult<DashboardBiModels.Segmenters> segmenters(
            SessionIdentity identity, RequestMetadata metadata);

    PersistenceResult<DashboardBiModels.Snapshot> load(
            DashboardBiModels.Filter filter, SessionIdentity identity, RequestMetadata metadata);
}
