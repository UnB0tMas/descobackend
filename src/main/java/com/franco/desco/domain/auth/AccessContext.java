package com.franco.desco.domain.auth;

import java.util.List;

public record AccessContext(
        AccessUser usuario,
        List<AccessRole> roles,
        List<AccessModule> modulos,
        List<AccessPermission> permisos
) {
    public AccessContext {
        roles = roles == null ? List.of() : List.copyOf(roles);
        modulos = modulos == null ? List.of() : List.copyOf(modulos);
        permisos = permisos == null ? List.of() : List.copyOf(permisos);
    }
}
