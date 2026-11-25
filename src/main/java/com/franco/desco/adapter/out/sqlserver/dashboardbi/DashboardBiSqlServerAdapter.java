package com.franco.desco.adapter.out.sqlserver.dashboardbi;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.JsonPaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.dashboardbi.DashboardBiPort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.dashboardbi.DashboardBiModels;
import org.springframework.stereotype.Repository;

@Repository
public final class DashboardBiSqlServerAdapter extends JsonPaAdapterSupport implements DashboardBiPort {
    public DashboardBiSqlServerAdapter(SqlServerPaExecutor executor, PaPayloadFactory payloads,
                                       DatabaseRecordMapper mapper) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<DashboardBiModels.Segmenters> segmenters(
            SessionIdentity identity, RequestMetadata metadata) {
        return one("reporte.PA_DashboardBI_Sel_Segmentadores", null, identity, metadata,
                DashboardBiModels.Segmenters.class);
    }

    @Override
    public PersistenceResult<DashboardBiModels.Snapshot> load(DashboardBiModels.Filter filter,
            SessionIdentity identity, RequestMetadata metadata) {
        return one("reporte.PA_DashboardBI_Sel_Resumen", filter, identity, metadata,
                DashboardBiModels.Snapshot.class);
    }
}
