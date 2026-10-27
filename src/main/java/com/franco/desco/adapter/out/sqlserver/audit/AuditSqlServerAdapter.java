package com.franco.desco.adapter.out.sqlserver.audit;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.audit.*;
import com.franco.desco.application.audit.AuditCommands.*;
import com.franco.desco.application.audit.port.out.AuditPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.audit.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class AuditSqlServerAdapter
        extends JsonPaAdapterSupport
        implements AuditPersistencePort {

    public AuditSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<AuditModels.Summary>> list(ListAudit c,SessionIdentity i,RequestMetadata m) {
        return page("auditoria.PA_Auditoria_Sel_Listado", c, i, m, AuditModels.Summary.class);
    }

    @Override
    public PersistenceResult<AuditModels.Detail> get(GetAudit c,SessionIdentity i,RequestMetadata m) {
        return one("auditoria.PA_Auditoria_Sel_Detalle", c, i, m, AuditModels.Detail.class);
    }

    @Override
    public PersistenceResult<List<AuditModels.ExportRow>> export(ExportAudit c,SessionIdentity i,RequestMetadata m) {
        return list("auditoria.PA_Auditoria_Sel_Exportacion", c, i, m, AuditModels.ExportRow.class);
    }

}
