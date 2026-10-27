package com.franco.desco.application.catalog.port.out;

import com.franco.desco.application.catalog.*;
import com.franco.desco.application.catalog.CatalogCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.catalog.*;
import java.util.*;

public interface CatalogPersistencePort {
    PersistenceResult<PageResult<CatalogModels.Item>> list(ListCatalog c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateCatalog c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(UpdateCatalog c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> disable(DisableCatalog c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<List<CatalogModels.Department>> departments(ListDepartments c);
    PersistenceResult<List<CatalogModels.Province>> provinces(ListProvinces c);
    PersistenceResult<List<CatalogModels.District>> districts(ListDistricts c);
    PersistenceResult<List<CatalogModels.PopulationCenter>> populationCenters(ListPopulationCenters c);
}
