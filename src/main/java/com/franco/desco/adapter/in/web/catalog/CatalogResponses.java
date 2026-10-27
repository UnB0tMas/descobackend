package com.franco.desco.adapter.in.web.catalog;

import io.swagger.v3.oas.annotations.media.Schema;

public final class CatalogResponses {

    private CatalogResponses() {
    }

    @Schema(name = "CatalogItemResponse")
    public record Item(
            Long id,
            String codigo,
            String nombre,
            String descripcion,
            boolean estado,
            @Schema(
                    description = "Cantidad de referencias actuales al valor dentro de los procesos del sistema.",
                    example = "3"
            )
            long cantidadUso,
            @Schema(
                    description = "Indica si el valor ya está siendo utilizado y, por tanto, su retiro puede estar restringido."
            )
            boolean enUso
    ) {
    }

    @Schema(name = "CatalogCreatedResponse")
    public record Created(Long id) {
    }

    @Schema(name = "DepartmentResponse")
    public record Department(
            String departamentoCodigo,
            String departamentoNombre
    ) {
    }

    @Schema(name = "ProvinceResponse")
    public record Province(
            String provinciaCodigo,
            String provinciaNombre
    ) {
    }

    @Schema(name = "DistrictResponse")
    public record District(
            String distritoCodigo,
            String distritoNombre
    ) {
    }

    @Schema(name = "PopulationCenterResponse")
    public record PopulationCenter(
            Long centroPobladoId,
            String codigoInei,
            String centroPobladoNombre
    ) {
    }
}
