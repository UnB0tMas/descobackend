package com.franco.desco.domain.auth;

import java.time.Instant;
import java.util.UUID;

public record AccessUser(
        Long usuarioId,
        String nombreUsuario,
        String estadoCuenta,
        Instant ultimoAccesoCorrectoUtc,
        boolean requiereCambioPassword,
        boolean segundoFactorHabilitado,
        Integer tokenVersion,
        Long personaId,
        String tipoDocumento,
        String numeroDocumento,
        String nombres,
        String apellidoPaterno,
        String apellidoMaterno,
        String nombreCompleto,
        String telefono,
        String codigoEmpleado,
        Long empresaId,
        String correoSeguridad,
        boolean correoSeguridadVerificado,
        UUID sesionPublicaId,
        Instant fechaSesionUtc,
        Instant fechaExpiracionRenovacionUtc,
        Long dispositivoUsuarioId,
        String navegador,
        String sistemaOperativo,
        boolean dispositivoReconocido
) {
}
