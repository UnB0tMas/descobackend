package com.franco.desco.application.catalog.service;

import com.franco.desco.application.catalog.CatalogCommands.CreateCatalog;
import com.franco.desco.application.catalog.CatalogCommands.DisableCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListDepartments;
import com.franco.desco.application.catalog.CatalogCommands.ListDistricts;
import com.franco.desco.application.catalog.CatalogCommands.ListPopulationCenters;
import com.franco.desco.application.catalog.CatalogCommands.ListProvinces;
import com.franco.desco.application.catalog.CatalogCommands.UpdateCatalog;
import com.franco.desco.application.catalog.port.in.CatalogUseCase;
import com.franco.desco.application.catalog.port.out.CatalogPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.catalog.CatalogModels;

import java.util.List;

public final class CatalogApplicationService
        implements CatalogUseCase {

    private final CatalogPersistencePort persistence;

    public CatalogApplicationService(
            CatalogPersistencePort persistence
    ) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<PageResult<CatalogModels.Item>> list(
            ListCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.list(
                        command,
                        identity,
                        metadata
                ),
                "CATALOGO_LISTADO",
                "CATALOGO_NO_LISTADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Long> create(
            CreateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.create(
                        command,
                        identity,
                        metadata
                ),
                "CATALOGO_CREADO",
                "CATALOGO_NO_CREADO"
        );
    }

    @Override
    public AppResult<Void> update(
            UpdateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.update(
                        command,
                        identity,
                        metadata
                ),
                "CATALOGO_ACTUALIZADO",
                "CATALOGO_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> disable(
            DisableCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.disable(
                        command,
                        identity,
                        metadata
                ),
                "CATALOGO_DESHABILITADO",
                "CATALOGO_NO_DESHABILITADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<CatalogModels.Department>> departments(
            ListDepartments command
    ) {
        return ApplicationResults.ok(
                persistence.departments(command),
                "DEPARTAMENTOS_LISTADOS",
                "GEOGRAFIA_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<CatalogModels.Province>> provinces(
            ListProvinces command
    ) {
        return ApplicationResults.ok(
                persistence.provinces(command),
                "PROVINCIAS_LISTADAS",
                "GEOGRAFIA_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<CatalogModels.District>> districts(
            ListDistricts command
    ) {
        return ApplicationResults.ok(
                persistence.districts(command),
                "DISTRITOS_LISTADOS",
                "GEOGRAFIA_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<CatalogModels.PopulationCenter>> populationCenters(
            ListPopulationCenters command
    ) {
        return ApplicationResults.ok(
                persistence.populationCenters(command),
                "CENTROS_POBLADOS_LISTADOS",
                "GEOGRAFIA_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }
}
