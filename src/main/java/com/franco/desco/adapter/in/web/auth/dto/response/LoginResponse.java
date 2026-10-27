package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(
        name = "LoginResponse",
        description = "Resultado del proceso de login. Dependiendo de 'paso', puede contener tokens/contexto o un desafío pendiente."
)
public record LoginResponse(

        @Schema(
                example = "AUTENTICADO",
                description = "Paso resultante del login."
        )
        String paso,

        @Schema(
                description = "Tokens cuando el login ya quedó autenticado.",
                nullable = true
        )
        TokenResponse tokens,

        @Schema(
                description = "Contexto de acceso cuando la sesión fue creada.",
                nullable = true
        )
        AuthContextResponse contexto,

        @Schema(
                description = "Desafío pendiente cuando debe completarse verificación de correo o segundo factor.",
                nullable = true
        )
        AuthChallengeResponse desafio
) {
}
