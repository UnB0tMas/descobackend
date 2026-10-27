package com.franco.desco.adapter.out.sqlserver.catalog;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.catalog.*;
import com.franco.desco.application.catalog.CatalogCommands.*;
import com.franco.desco.application.catalog.port.out.CatalogPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.catalog.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CatalogSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CatalogPersistencePort {

    public CatalogSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CatalogModels.Item>> list(ListCatalog c,SessionIdentity i,RequestMetadata m) {
        return page("config.PA_Catalogo_Sel_Listado", c, i, m, CatalogModels.Item.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateCatalog c,SessionIdentity i,RequestMetadata m) {
        return create("config.PA_Catalogo_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateCatalog c,SessionIdentity i,RequestMetadata m) {
        return mutate("config.PA_Catalogo_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> disable(DisableCatalog c,SessionIdentity i,RequestMetadata m) {
        return mutate("config.PA_Catalogo_Upd_Deshabilitar", c, i, m);
    }

    @Override
    public PersistenceResult<List<CatalogModels.Department>> departments(ListDepartments c) {
        return publicList("geo.PA_Departamento_Sel_Listado", c, CatalogModels.Department.class);
    }

    @Override
    public PersistenceResult<List<CatalogModels.Province>> provinces(ListProvinces c) {
        return publicList("geo.PA_Provincia_Sel_PorDepartamento", c, CatalogModels.Province.class);
    }

    @Override
    public PersistenceResult<List<CatalogModels.District>> districts(ListDistricts c) {
        return publicList("geo.PA_Distrito_Sel_PorProvincia", c, CatalogModels.District.class);
    }

    @Override
    public PersistenceResult<List<CatalogModels.PopulationCenter>> populationCenters(ListPopulationCenters c) {
        return publicList("geo.PA_CentroPoblado_Sel_PorDistrito", c, CatalogModels.PopulationCenter.class);
    }

}
