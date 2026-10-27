package com.franco.desco.application.report.port.out;

import com.franco.desco.application.report.*;
import com.franco.desco.application.report.ReportCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.report.*;
import java.util.*;

public interface ReportPersistencePort {
    PersistenceResult<List<ReportModels.CatalogItem>> catalog(SessionIdentity i,RequestMetadata m);
    PersistenceResult<ReportModels.Data> data(GetData c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<ReportModels.Data> export(ExportData c,SessionIdentity i,RequestMetadata m);
}
