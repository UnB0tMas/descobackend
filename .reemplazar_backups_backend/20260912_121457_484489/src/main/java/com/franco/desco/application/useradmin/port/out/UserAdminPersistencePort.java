package com.franco.desco.application.useradmin.port.out;

import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.application.useradmin.UserAdminCommands.*;
import com.franco.desco.domain.useradmin.UserAdminModels;

public interface UserAdminPersistencePort {
    PersistenceResult<PageResult<UserAdminModels.Summary>> list(ListUsers command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<UserAdminModels.Detail> get(GetUser command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(CreateUserPersist command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> update(UpdateUser command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> disable(DisableUser command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> reactivate(ReactivateUser command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> assignRole(AssignRole command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> removeRole(RemoveRole command, SessionIdentity identity, RequestMetadata metadata);
}
