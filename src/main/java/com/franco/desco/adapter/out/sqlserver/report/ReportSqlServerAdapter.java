package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.report.*;
import com.franco.desco.application.report.ReportCommands.*;
import com.franco.desco.application.report.port.out.ReportPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.report.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class ReportSqlServerAdapter
        extends JsonPaAdapterSupport
        implements ReportPersistencePort {

    public ReportSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<List<ReportModels.CatalogItem>> catalog(SessionIdentity i,RequestMetadata m) {
        return list("reporte.PA_Reporte_Sel_Catalogo", null, i, m, ReportModels.CatalogItem.class);
    }

    @Override
    public PersistenceResult<ReportModels.Data> data(GetData c,SessionIdentity i,RequestMetadata m) {
        return one("reporte.PA_Reporte_Sel_Datos", c, i, m, ReportModels.Data.class);
    }

    @Override
    public PersistenceResult<ReportModels.Data> export(ExportData c,SessionIdentity i,RequestMetadata m) {
        return one("reporte.PA_Reporte_Sel_Exportacion", c, i, m, ReportModels.Data.class);
    }

}
