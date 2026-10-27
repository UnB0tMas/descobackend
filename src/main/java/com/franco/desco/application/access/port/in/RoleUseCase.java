package com.franco.desco.application.access.port.in;
import com.franco.desco.application.access.RoleCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.access.RoleModels;
public interface RoleUseCase { AppResult<PageResult<RoleModels.Summary>> list(ListRoles c,SessionIdentity i,RequestMetadata m); AppResult<RoleModels.Detail> get(GetRole c,SessionIdentity i,RequestMetadata m); AppResult<Long> create(CreateRole c,SessionIdentity i,RequestMetadata m); AppResult<Void> update(UpdateRole c,SessionIdentity i,RequestMetadata m); AppResult<Void> disable(DisableRole c,SessionIdentity i,RequestMetadata m); AppResult<Void> updatePermissions(UpdatePermissions c,SessionIdentity i,RequestMetadata m); }
