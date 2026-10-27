package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.UUID;

@Schema(
        name = "AuthChallengeResponse",
        description = "Información necesaria para continuar un desafío de autenticación."
)
public record AuthChallengeResponse(

        @Schema(
                description = "Paso siguiente requerido por el flujo.",
                example = "SEGUNDO_FACTOR"
        )
        String paso,

        @Schema(
                description = "Identificador del usuario asociado al desafío.",
                example = "25"
        )
        Long usuarioId,

        @Schema(
                description = "Nombre de usuario.",
                example = "jfranco"
        )
        String nombreUsuario,

        @Schema(
                description = "Correlación del proceso de autenticación.",
                example = "ba39b415-8a53-4d35-9a21-384cb0a8eb05",
                format = "uuid"
        )
        UUID correlacionId,

        @Schema(
                description = "Correo de seguridad parcialmente enmascarado.",
                example = "j***@correo.com"
        )
        String correoEnmascarado
) {
}
