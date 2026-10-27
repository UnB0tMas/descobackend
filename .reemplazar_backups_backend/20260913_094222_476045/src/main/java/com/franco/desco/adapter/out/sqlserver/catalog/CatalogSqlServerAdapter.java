package com.franco.desco.adapter.out.sqlserver.catalog;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.JsonPaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.catalog.CatalogCommands.CreateCatalog;
import com.franco.desco.application.catalog.CatalogCommands.DisableCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListCatalog;
import com.franco.desco.application.catalog.CatalogCommands.ListDepartments;
import com.franco.desco.application.catalog.CatalogCommands.ListDistricts;
import com.franco.desco.application.catalog.CatalogCommands.ListPopulationCenters;
import com.franco.desco.application.catalog.CatalogCommands.ListProvinces;
import com.franco.desco.application.catalog.CatalogCommands.UpdateCatalog;
import com.franco.desco.application.catalog.port.out.CatalogPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.catalog.CatalogModels;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public final class CatalogSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CatalogPersistencePort {

    public CatalogSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(
                executor,
                payloads,
                mapper
        );
    }

    @Override
    public PersistenceResult<PageResult<CatalogModels.Item>> list(
            ListCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return page(
                "config.PA_Catalogo_Sel_Listado",
                command,
                identity,
                metadata,
                CatalogModels.Item.class
        );
    }

    @Override
    public PersistenceResult<Long> create(
            CreateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return create(
                "config.PA_Catalogo_Ins_Registro",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> update(
            UpdateCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return mutate(
                "config.PA_Catalogo_Upd_Registro",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<Void> disable(
            DisableCatalog command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return mutate(
                "config.PA_Catalogo_Upd_Deshabilitar",
                command,
                identity,
                metadata
        );
    }

    @Override
    public PersistenceResult<List<CatalogModels.Department>> departments(
            ListDepartments command
    ) {
        /*
         * Este PA no recibe @cJson; solamente expone parámetros de salida.
         */
        return publicList(
                "geo.PA_Departamento_Sel_Listado",
                command,
                CatalogModels.Department.class
        );
    }

    @Override
    public PersistenceResult<List<CatalogModels.Province>> provinces(
            ListProvinces command
    ) {
        /*
         * Los PA territoriales actuales reciben @cJson. El helper list(...)
         * construye ese contrato y mantiene departamentoCodigo en la raíz,
         * que es exactamente lo que lee OPENJSON en SQL Server.
         */
        return list(
                "geo.PA_Provincia_Sel_PorDepartamento",
                command,
                null,
                null,
                CatalogModels.Province.class
        );
    }

    @Override
    public PersistenceResult<List<CatalogModels.District>> districts(
            ListDistricts command
    ) {
        return list(
                "geo.PA_Distrito_Sel_PorProvincia",
                command,
                null,
                null,
                CatalogModels.District.class
        );
    }

    @Override
    public PersistenceResult<List<CatalogModels.PopulationCenter>> populationCenters(
            ListPopulationCenters command
    ) {
        return list(
                "geo.PA_CentroPoblado_Sel_PorDistrito",
                command,
                null,
                null,
                CatalogModels.PopulationCenter.class
        );
    }
}
