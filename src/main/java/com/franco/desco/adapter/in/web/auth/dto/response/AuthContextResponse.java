package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(
        name = "AuthContextResponse",
        description = "Contexto efectivo de acceso utilizado por Angular para construir navegación y controles."
)
public record AuthContextResponse(

        @Schema(
                description = "Datos del usuario y de la sesión."
        )
        UserAccessResponse usuario,

        @Schema(
                description = "Roles activos asignados al usuario."
        )
        List<RoleAccessResponse> roles,

        @Schema(
                description = "Módulos visibles o accesibles."
        )
        List<ModuleAccessResponse> modulos,

        @Schema(
                description = "Permisos efectivos del usuario."
        )
        List<PermissionAccessResponse> permisos
) {
}
