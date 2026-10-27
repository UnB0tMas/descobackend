package com.franco.desco.application.report.service;

import com.franco.desco.application.report.ReportCommands.*;
import com.franco.desco.application.report.port.in.ReportUseCase;
import com.franco.desco.application.report.port.out.ReportPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.report.ReportModels;
import java.util.List;

public final class ReportApplicationService implements ReportUseCase {
    private final ReportPersistencePort persistence;
    public ReportApplicationService(ReportPersistencePort persistence){this.persistence=persistence;}

    public AppResult<List<ReportModels.CatalogItem>> catalog(SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.catalog(i,m),"REPORTES_CATALOGO_OBTENIDO","REPORTES_CATALOGO_NO_DISPONIBLE",AppStatus.BAD_REQUEST);
    }
    public AppResult<ReportModels.Data> data(GetData c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.data(c,i,m),"REPORTE_OBTENIDO","REPORTE_NO_DISPONIBLE",AppStatus.BAD_REQUEST);
    }
    public AppResult<ReportModels.Data> export(ExportData c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.export(c,i,m),"REPORTE_EXPORTACION_PREPARADA","REPORTE_EXPORTACION_NO_DISPONIBLE",AppStatus.BAD_REQUEST);
    }
}
