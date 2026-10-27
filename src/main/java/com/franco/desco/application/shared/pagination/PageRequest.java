package com.franco.desco.application.shared.pagination;

public record PageRequest<F>(
        int pagina,
        int tamanio,
        F filtros,
        String ordenCampo,
        String ordenDireccion
) {
}
