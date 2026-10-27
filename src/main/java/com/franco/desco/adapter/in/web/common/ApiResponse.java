package com.franco.desco.adapter.in.web.common;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(
        description = "Envelope HTTP estándar utilizado por toda la API DESCO. El esquema se especializa según el tipo de datos de cada endpoint."
)
public record ApiResponse<T>(

        @Schema(
                description = "Indica si la operación fue procesada satisfactoriamente.",
                example = "true"
        )
        boolean exitoso,

        @Schema(
                description = "Código funcional estable de la respuesta.",
                example = "OPERACION_EXITOSA"
        )
        String codigo,

        @Schema(
                description = "Mensaje funcional comprensible para el usuario. Nunca contiene errores técnicos internos.",
                example = "La operación se realizó correctamente."
        )
        String mensaje,

        @Schema(
                description = "Datos tipados devueltos por la operación. Puede ser nulo cuando la operación no necesita retornar información.",
                nullable = true
        )
        T datos,

        @Schema(
                description = "Identificador de correlación de la solicitud.",
                example = "8f2da1cf-9a3e-4c03-a90c-12bc20f34625",
                format = "uuid"
        )
        UUID correlacionId,

        @Schema(
                description = "Fecha y hora UTC en la que el backend construyó la respuesta.",
                example = "2026-08-29T18:30:15Z",
                format = "date-time"
        )
        Instant fechaHoraUtc
) {
}
