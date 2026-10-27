package com.franco.desco.adapter.in.web.auth.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.util.UUID;

@Schema(
        name = "UserAccessResponse",
        description = "Identidad y estado de seguridad del usuario autenticado."
)
public record UserAccessResponse(

        @Schema(
                example = "25",
                description = "Identificador del usuario."
        )
        Long usuarioId,

        @Schema(
                example = "jfranco",
                description = "Nombre de usuario."
        )
        String nombreUsuario,

        @Schema(
                example = "ACTIVO",
                description = "Estado funcional de la cuenta."
        )
        String estadoCuenta,

        @Schema(
                format = "date-time",
                description = "Último acceso correcto registrado."
        )
        Instant ultimoAccesoCorrectoUtc,

        @Schema(
                description = "Indica si el usuario debe cambiar su contraseña."
        )
        boolean requiereCambioPassword,

        @Schema(
                description = "Indica si la cuenta tiene habilitado segundo factor."
        )
        boolean segundoFactorHabilitado,

        @Schema(
                description = "Versión vigente utilizada para invalidación de tokens.",
                example = "1"
        )
        Integer tokenVersion,

        @Schema(
                description = "Identificador de la persona."
        )
        Long personaId,

        @Schema(
                example = "DNI",
                description = "Tipo de documento."
        )
        String tipoDocumento,

        @Schema(
                example = "12345678",
                description = "Número de documento."
        )
        String numeroDocumento,

        @Schema(
                example = "Jorge",
                description = "Nombres."
        )
        String nombres,

        @Schema(
                example = "Franco",
                description = "Apellido paterno."
        )
        String apellidoPaterno,

        @Schema(
                example = "López",
                description = "Apellido materno."
        )
        String apellidoMaterno,

        @Schema(
                example = "Jorge Franco López",
                description = "Nombre completo."
        )
        String nombreCompleto,

        @Schema(
                example = "999999999",
                description = "Teléfono registrado."
        )
        String telefono,

        @Schema(
                example = "EMP-001",
                description = "Código del empleado."
        )
        String codigoEmpleado,

        @Schema(
                description = "Identificador de empresa."
        )
        Long empresaId,

        @Schema(
                example = "usuario@desco.org.pe",
                description = "Correo de seguridad."
        )
        String correoSeguridad,

        @Schema(
                description = "Indica si el correo de seguridad ya fue verificado."
        )
        boolean correoSeguridadVerificado,

        @Schema(
                format = "uuid",
                description = "Identificador público de la sesión."
        )
        UUID sesionPublicaId,

        @Schema(
                format = "date-time",
                description = "Fecha de creación de la sesión."
        )
        Instant fechaSesionUtc,

        @Schema(
                format = "date-time",
                description = "Fecha de expiración de la renovación de sesión."
        )
        Instant fechaExpiracionRenovacionUtc,

        @Schema(
                description = "Identificador de la relación usuario-dispositivo."
        )
        Long dispositivoUsuarioId,

        @Schema(
                example = "Chrome",
                description = "Navegador detectado."
        )
        String navegador,

        @Schema(
                example = "Windows",
                description = "Sistema operativo detectado."
        )
        String sistemaOperativo,

        @Schema(
                description = "Indica si el dispositivo está reconocido."
        )
        boolean dispositivoReconocido
) {
}
