package com.franco.desco.application.dashboard.port.out;

import com.franco.desco.application.dashboard.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.dashboard.*;
import java.util.*;

public interface DashboardPersistencePort {
    PersistenceResult<DashboardModels.Summary> summary(SessionIdentity identity, RequestMetadata metadata, DashboardModels.Filter filter);
}
