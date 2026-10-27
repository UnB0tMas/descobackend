package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "RoleAccessResponse",
        description = "Rol activo asignado al usuario. Los roles agrupan permisos y no sustituyen la autorización por permiso."
)
public record RoleAccessResponse(

        @Schema(
                example = "4",
                description = "Identificador del rol."
        )
        Long rolId,

        @Schema(
                example = "TECNICO_CAMPO",
                description = "Código estable del rol."
        )
        String codigo,

        @Schema(
                example = "Técnico de campo",
                description = "Nombre visible del rol."
        )
        String nombre,

        @Schema(
                description = "Descripción funcional del rol."
        )
        String descripcion,

        @Schema(
                description = "Indica si el rol exige segundo factor."
        )
        boolean requiereSegundoFactor
) {
}
