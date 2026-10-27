package com.franco.desco.adapter.out.sqlserver.dashboard;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.JsonPaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.dashboard.port.out.DashboardPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboard.DashboardModels;
import org.springframework.stereotype.Repository;

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
    public PersistenceResult<DashboardModels.Summary> summary(
            SessionIdentity identity,
            RequestMetadata metadata,
            DashboardModels.Filter filter
    ) {
        return one(
                "dbo.PA_Dashboard_Sel_Resumen",
                filter,
                identity,
                metadata,
                DashboardModels.Summary.class
        );
    }
}
