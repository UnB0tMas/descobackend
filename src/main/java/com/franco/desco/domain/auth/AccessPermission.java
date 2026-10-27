package com.franco.desco.domain.auth;

public record AccessPermission(
        Long permisoId,
        Integer moduloId,
        String codigoModulo,
        String codigo,
        String nombre,
        String descripcion,
        String accion,
        boolean sensible,
        boolean requiereMotivo
) {
}
