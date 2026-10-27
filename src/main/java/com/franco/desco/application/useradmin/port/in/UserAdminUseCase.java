package com.franco.desco.application.useradmin.port.in;

import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.application.useradmin.UserAdminCommands.*;
import com.franco.desco.domain.useradmin.UserAdminModels;

public interface UserAdminUseCase {
    AppResult<PageResult<UserAdminModels.Summary>> list(ListUsers command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<UserAdminModels.Detail> get(GetUser command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<UserAdminModels.SecurityPolicy> getSecurityPolicy(GetSecurityPolicy command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> updateSecurityPolicy(UpdateSecurityPolicy command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(CreateUser command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> update(UpdateUser command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> disable(DisableUser command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> reactivate(ReactivateUser command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> assignRole(AssignRole command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> removeRole(RemoveRole command, SessionIdentity identity, RequestMetadata metadata);
}
