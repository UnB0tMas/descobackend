package com.franco.desco.domain.catalog;

public final class CatalogModels {

    private CatalogModels() {
    }

    public record Item(
            Long id,
            String codigo,
            String nombre,
            String descripcion,
            boolean estado,
            long cantidadUso,
            boolean enUso
    ) {
    }

    public record Department(
            String departamentoCodigo,
            String departamentoNombre
    ) {
    }

    public record Province(
            String provinciaCodigo,
            String provinciaNombre
    ) {
    }

    public record District(
            String distritoCodigo,
            String distritoNombre
    ) {
    }

    public record PopulationCenter(
            Long centroPobladoId,
            String codigoInei,
            String centroPobladoNombre
    ) {
    }
}
