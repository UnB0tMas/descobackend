package com.franco.desco.application.useradmin.service;

import com.franco.desco.application.auth.port.out.PasswordHashPort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.application.useradmin.UserAdminCommands.*;
import com.franco.desco.application.useradmin.port.in.UserAdminUseCase;
import com.franco.desco.application.useradmin.port.out.UserAdminPersistencePort;
import com.franco.desco.domain.useradmin.UserAdminModels;

public final class UserAdminApplicationService implements UserAdminUseCase {
    private final UserAdminPersistencePort persistence;
    private final PasswordHashPort passwordHash;

    public UserAdminApplicationService(UserAdminPersistencePort persistence, PasswordHashPort passwordHash) {
        this.persistence = persistence;
        this.passwordHash = passwordHash;
    }

    public AppResult<PageResult<UserAdminModels.Summary>> list(ListUsers c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c,i,m), "USUARIOS_LISTADOS", "USUARIOS_NO_LISTADOS", AppStatus.BAD_REQUEST);
    }
    public AppResult<UserAdminModels.Detail> get(GetUser c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.get(c,i,m), "USUARIO_OBTENIDO", "USUARIO_NO_DISPONIBLE", AppStatus.NOT_FOUND);
    }
    public AppResult<Long> create(CreateUser c, SessionIdentity i, RequestMetadata m) {
        String hash = passwordHash.encode(c.passwordInicial());
        CreateUserPersist persisted = new CreateUserPersist(c.empleadoId(), c.nombreUsuario(), hash, c.correoSeguridad(), c.requiereCambioPassword(), c.rolIds());
        return ApplicationResults.created(persistence.create(persisted,i,m), "USUARIO_CREADO", "USUARIO_NO_CREADO");
    }
    public AppResult<Void> update(UpdateUser c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.update(c,i,m), "USUARIO_ACTUALIZADO", "USUARIO_NO_ACTUALIZADO", AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> disable(DisableUser c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.disable(c,i,m), "USUARIO_DESHABILITADO", "USUARIO_NO_DESHABILITADO", AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> reactivate(ReactivateUser c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.reactivate(c,i,m), "USUARIO_REACTIVADO", "USUARIO_NO_REACTIVADO", AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> assignRole(AssignRole c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.assignRole(c,i,m), "USUARIO_ROL_ASIGNADO", "USUARIO_ROL_NO_ASIGNADO", AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> removeRole(RemoveRole c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.removeRole(c,i,m), "USUARIO_ROL_RETIRADO", "USUARIO_ROL_NO_RETIRADO", AppStatus.BAD_REQUEST);
    }
}
