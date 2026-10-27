package com.franco.desco.application.audit.service;

import com.franco.desco.application.audit.AuditCommands.*;
import com.franco.desco.application.audit.port.in.AuditUseCase;
import com.franco.desco.application.audit.port.out.AuditPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.audit.AuditModels;
import java.util.List;

public final class AuditApplicationService implements AuditUseCase {
    private final AuditPersistencePort persistence;
    public AuditApplicationService(AuditPersistencePort persistence){this.persistence=persistence;}
    public AppResult<PageResult<AuditModels.Summary>> list(ListAudit c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.list(c,i,m),"AUDITORIA_LISTADA","AUDITORIA_NO_LISTADA",AppStatus.BAD_REQUEST);}
    public AppResult<AuditModels.Detail> get(GetAudit c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.get(c,i,m),"AUDITORIA_OBTENIDA","AUDITORIA_NO_DISPONIBLE",AppStatus.NOT_FOUND);}
    public AppResult<List<AuditModels.ExportRow>> export(ExportAudit c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(persistence.export(c,i,m),"AUDITORIA_EXPORTACION_PREPARADA","AUDITORIA_EXPORTACION_NO_DISPONIBLE",AppStatus.BAD_REQUEST);}
}
