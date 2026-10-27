package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "PermissionAccessResponse",
        description = "Permiso efectivo concedido al usuario por uno o varios roles."
)
public record PermissionAccessResponse(

        @Schema(
                description = "Identificador del permiso."
        )
        Long permisoId,

        @Schema(
                description = "Identificador del módulo al que pertenece."
        )
        Integer moduloId,

        @Schema(
                example = "PRODUCTORES",
                description = "Código del módulo."
        )
        String codigoModulo,

        @Schema(
                example = "PRODUCTORES_CREAR",
                description = "Código estable del permiso utilizado para autorización."
        )
        String codigo,

        @Schema(
                example = "Crear productores",
                description = "Nombre visible del permiso."
        )
        String nombre,

        @Schema(
                description = "Descripción funcional."
        )
        String descripcion,

        @Schema(
                example = "CREAR",
                description = "Acción modular asociada."
        )
        String accion,

        @Schema(
                description = "Indica si la acción se considera sensible."
        )
        boolean sensible,

        @Schema(
                description = "Indica si la operación requiere motivo trazable."
        )
        boolean requiereMotivo
) {
}
