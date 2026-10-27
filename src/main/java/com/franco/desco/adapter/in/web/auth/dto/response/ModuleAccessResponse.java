package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "ModuleAccessResponse",
        description = "Módulo visible o disponible para el usuario."
)
public record ModuleAccessResponse(

        @Schema(
                description = "Identificador del módulo."
        )
        Integer moduloId,

        @Schema(
                description = "Identificador del módulo padre cuando pertenece a un grupo.",
                nullable = true
        )
        Integer moduloPadreId,

        @Schema(
                example = "PRODUCTORES",
                description = "Código estable del módulo."
        )
        String codigo,

        @Schema(
                example = "Productores / socios",
                description = "Nombre visible del módulo."
        )
        String nombre,

        @Schema(
                description = "Orden relativo utilizado por el menú."
        )
        Integer orden,

        @Schema(
                example = "/gestion-tecnica/productores",
                description = "Ruta Angular asociada al módulo."
        )
        String ruta,

        @Schema(
                example = "users",
                description = "Identificador lógico del icono."
        )
        String icono,

        @Schema(
                description = "Indica si el módulo debe formar parte del menú."
        )
        boolean visibleMenu,

        @Schema(
                description = "Indica si el registro representa un agrupador de módulos."
        )
        boolean esGrupo
) {
}
