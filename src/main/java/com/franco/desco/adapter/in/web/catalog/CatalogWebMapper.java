package com.franco.desco.adapter.in.web.catalog;

import com.franco.desco.application.catalog.CatalogCommands.CreateCatalog;
import com.franco.desco.application.catalog.CatalogCommands.DisableCatalog;
import com.franco.desco.application.catalog.CatalogCommands.Filter;
import com.franco.desco.application.catalog.CatalogCommands.ListCatalog;
import com.franco.desco.application.catalog.CatalogCommands.UpdateCatalog;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.catalog.CatalogModels;
import org.springframework.stereotype.Component;

@Component
public class CatalogWebMapper {

    public ListCatalog list(
            String catalog,
            int page,
            int size
    ) {
        return new ListCatalog(
                new PageRequest<>(
                        page,
                        size,
                        new Filter(catalog),
                        null,
                        null
                )
        );
    }

    public CreateCatalog command(
            CatalogRequests.Create request
    ) {
        return new CreateCatalog(
                request.catalogo(),
                request.codigo(),
                request.nombre(),
                request.descripcion(),
                request.categoria()
        );
    }

    public UpdateCatalog command(
            Long id,
            CatalogRequests.Update request
    ) {
        return new UpdateCatalog(
                request.catalogo(),
                id,
                request.nombre(),
                request.descripcion(),
                request.categoria()
        );
    }

    public DisableCatalog command(
            Long id,
            CatalogRequests.Disable request
    ) {
        return new DisableCatalog(
                request.catalogo(),
                id,
                request.motivo()
        );
    }

    public CatalogResponses.Item response(
            CatalogModels.Item value
    ) {
        return new CatalogResponses.Item(
                value.id(),
                value.codigo(),
                value.nombre(),
                value.descripcion(),
                value.estado(),
                value.cantidadUso(),
                value.enUso()
        );
    }
}
