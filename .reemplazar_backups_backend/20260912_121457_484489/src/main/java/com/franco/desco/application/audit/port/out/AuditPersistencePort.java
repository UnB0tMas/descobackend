package com.franco.desco.application.audit.port.out;

import com.franco.desco.application.audit.AuditCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.audit.AuditModels;
import java.util.List;

public interface AuditPersistencePort {
    PersistenceResult<PageResult<AuditModels.Summary>> list(ListAudit command,SessionIdentity identity,RequestMetadata metadata);
    PersistenceResult<AuditModels.Detail> get(GetAudit command,SessionIdentity identity,RequestMetadata metadata);
    PersistenceResult<List<AuditModels.ExportRow>> export(ExportAudit command,SessionIdentity identity,RequestMetadata metadata);
}
