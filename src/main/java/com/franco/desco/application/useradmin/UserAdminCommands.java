package com.franco.desco.application.useradmin;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.util.List;

public final class UserAdminCommands {
    private UserAdminCommands() {}

    public record UserFilter(String estadoCuenta, Long empresaId) {}
    public record ListUsers(PageRequest<UserFilter> page) {}
    public record GetUser(Long usuarioId) {}
    public record GetSecurityPolicy() {}
    public record UpdateSecurityPolicy(Integer diasDispositivoReconocido) {}
    public record CreateUser(Long empleadoId, String nombreUsuario, String passwordInicial, String correoSeguridad, boolean requiereCambioPassword, List<Long> rolIds) {
        public CreateUser { rolIds = rolIds == null ? List.of() : List.copyOf(rolIds); }
    }
    public record CreateUserPersist(Long empleadoId, String nombreUsuario, String passwordHash, String correoSeguridad, boolean requiereCambioPassword, List<Long> rolIds) {
        public CreateUserPersist { rolIds = rolIds == null ? List.of() : List.copyOf(rolIds); }
    }
    public record UpdateUser(Long usuarioId, String nombreUsuario, Boolean requiereCambioPassword, Boolean segundoFactorHabilitado) {}
    public record DisableUser(Long usuarioId, String motivo) {}
    public record ReactivateUser(Long usuarioId, String motivo) {}
    public record AssignRole(Long usuarioId, Long rolId) {}
    public record RemoveRole(Long usuarioId, Long rolId, String motivo) {}
}
