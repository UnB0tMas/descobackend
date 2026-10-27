package com.franco.desco.adapter.out.sqlserver.dashboard;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.dashboard.*;
import com.franco.desco.application.dashboard.port.out.DashboardPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.dashboard.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class DashboardSqlServerAdapter
        extends JsonPaAdapterSupport
        implements DashboardPersistencePort {

    public DashboardSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<DashboardModels.Summary> summary(SessionIdentity identity, RequestMetadata metadata, DashboardModels.Filter filter) {
        return one("dbo.PA_Dashboard_Sel_Resumen", filter, identity, metadata, DashboardModels.Summary.class);
    }

}
