package com.franco.desco.application.access.port.out;

import com.franco.desco.application.access.*;
import com.franco.desco.application.access.RoleCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.access.*;
import java.util.*;

public interface RolePersistencePort {
    PersistenceResult<PageResult<RoleModels.Summary>> list(ListRoles c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<RoleModels.Detail> get(GetRole c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateRole c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(UpdateRole c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> disable(DisableRole c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> updatePermissions(UpdatePermissions c,SessionIdentity i,RequestMetadata m);
}
