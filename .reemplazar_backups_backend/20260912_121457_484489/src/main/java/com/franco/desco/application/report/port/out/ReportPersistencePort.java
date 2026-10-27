package com.franco.desco.application.report.port.out;

import com.franco.desco.application.report.ReportCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.report.ReportModels;
import java.util.List;

public interface ReportPersistencePort {
    PersistenceResult<List<ReportModels.CatalogItem>> catalog(SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<ReportModels.Data> data(GetData command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<ReportModels.Data> export(ExportData command, SessionIdentity identity, RequestMetadata metadata);
}
