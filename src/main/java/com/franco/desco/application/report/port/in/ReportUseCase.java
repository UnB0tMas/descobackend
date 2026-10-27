package com.franco.desco.application.report.port.in;

import com.franco.desco.application.report.ReportCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.report.ReportModels;
import java.util.List;

public interface ReportUseCase {
    AppResult<List<ReportModels.CatalogItem>> catalog(SessionIdentity identity, RequestMetadata metadata);
    AppResult<ReportModels.Data> data(GetData command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<ReportModels.Data> export(ExportData command, SessionIdentity identity, RequestMetadata metadata);
}
