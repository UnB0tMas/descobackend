package com.franco.desco.application.shared.pagination;

import java.util.List;

public record PageResult<T>(
        List<T> items,
        int pagina,
        int tamanio,
        long totalRegistros,
        int totalPaginas
) {
    public PageResult {
        items = items == null
                ? List.of()
                : List.copyOf(items);
    }
}
