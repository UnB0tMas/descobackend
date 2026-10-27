package com.franco.desco.domain.auth;

public record AccessRole(
        Long rolId,
        String codigo,
        String nombre,
        String descripcion,
        boolean requiereSegundoFactor
) {
}
