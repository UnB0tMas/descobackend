package com.franco.desco.application.audit.port.out;

import com.franco.desco.application.audit.*;
import com.franco.desco.application.audit.AuditCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.audit.*;
import java.util.*;

public interface AuditPersistencePort {
    PersistenceResult<PageResult<AuditModels.Summary>> list(ListAudit c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<AuditModels.Detail> get(GetAudit c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<List<AuditModels.ExportRow>> export(ExportAudit c,SessionIdentity i,RequestMetadata m);
}
