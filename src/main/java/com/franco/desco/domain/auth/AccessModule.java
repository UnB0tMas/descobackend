package com.franco.desco.domain.auth;

public record AccessModule(
        Integer moduloId,
        Integer moduloPadreId,
        String codigo,
        String nombre,
        Integer orden,
        String ruta,
        String icono,
        boolean visibleMenu,
        boolean esGrupo
) {
}
