package com.franco.desco.adapter.in.web.common.pagination;

import com.franco.desco.application.shared.pagination.PageResult;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;
import java.util.function.Function;

@Schema(
        name = "PageResponse",
        description = "Respuesta paginada estándar de la API DESCO. La paginación y el total real son calculados por el procedimiento almacenado."
)
public record PageResponse<T>(

        @Schema(
                description = "Elementos de la página actual."
        )
        List<T> items,

        @Schema(
                description = "Número de página solicitado.",
                example = "1"
        )
        int pagina,

        @Schema(
                description = "Cantidad máxima de registros solicitados por página.",
                example = "20"
        )
        int tamanio,

        @Schema(
                description = "Cantidad total de registros que cumplen los filtros.",
                example = "125"
        )
        long totalRegistros,

        @Schema(
                description = "Cantidad total de páginas.",
                example = "7"
        )
        int totalPaginas
) {
    public PageResponse {
        items = items == null
                ? List.of()
                : List.copyOf(items);
    }

    public static <S, T> PageResponse<T> from(
            PageResult<S> result,
            Function<S, T> mapper
    ) {
        List<T> mapped = result.items()
                .stream()
                .map(mapper)
                .toList();

        return new PageResponse<>(
                mapped,
                result.pagina(),
                result.tamanio(),
                result.totalRegistros(),
                result.totalPaginas()
        );
    }
}
