package com.franco.desco.adapter.out.sqlserver.access;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.access.*;
import com.franco.desco.application.access.RoleCommands.*;
import com.franco.desco.application.access.port.out.RolePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.access.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class RoleSqlServerAdapter
        extends JsonPaAdapterSupport
        implements RolePersistencePort {

    public RoleSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<RoleModels.Summary>> list(ListRoles c,SessionIdentity i,RequestMetadata m) {
        return page("seg.PA_Rol_Sel_Listado", c, i, m, RoleModels.Summary.class);
    }

    @Override
    public PersistenceResult<RoleModels.Detail> get(GetRole c,SessionIdentity i,RequestMetadata m) {
        return one("seg.PA_Rol_Sel_Detalle", c, i, m, RoleModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateRole c,SessionIdentity i,RequestMetadata m) {
        return create("seg.PA_Rol_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateRole c,SessionIdentity i,RequestMetadata m) {
        return mutate("seg.PA_Rol_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> disable(DisableRole c,SessionIdentity i,RequestMetadata m) {
        return mutate("seg.PA_Rol_Upd_Deshabilitar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updatePermissions(UpdatePermissions c,SessionIdentity i,RequestMetadata m) {
        return mutate("seg.PA_RolPermiso_Upd_Asignaciones", c, i, m);
    }

}
