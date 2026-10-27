package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "RefreshResponse",
        description = "Resultado de una rotación correcta del refresh token."
)
public record RefreshResponse(

        @Schema(
                description = "Nuevos tokens emitidos."
        )
        TokenResponse tokens,

        @Schema(
                description = "Contexto vigente de acceso luego de renovar la sesión."
        )
        AuthContextResponse contexto
) {
}
