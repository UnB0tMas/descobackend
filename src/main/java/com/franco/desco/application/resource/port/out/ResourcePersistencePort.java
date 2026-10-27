package com.franco.desco.application.resource.port.out;

import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.resource.ResourceModels;

import java.util.List;

public interface ResourcePersistencePort {
    PersistenceResult<List<ResourceModels.Asset>> assets(SessionIdentity identity, Long uotId);
    PersistenceResult<ResourceModels.AssetDetail> asset(SessionIdentity identity, Long assetId);
    PersistenceResult<Long> createAsset(SessionIdentity identity, ResourceCommands.CreateAsset command);
    PersistenceResult<Void> updateAsset(SessionIdentity identity, ResourceCommands.UpdateAsset command);
    PersistenceResult<Void> changeAssetState(SessionIdentity identity, ResourceCommands.ChangeAssetState command);
    PersistenceResult<Long> reportIncident(SessionIdentity identity, ResourceCommands.ReportIncident command);
    PersistenceResult<List<ResourceModels.Product>> products(SessionIdentity identity, Long uotId);
    PersistenceResult<Long> createProduct(SessionIdentity identity, ResourceCommands.CreateProduct command);
    PersistenceResult<Long> versionPrice(SessionIdentity identity, ResourceCommands.VersionPrice command);
    PersistenceResult<List<ResourceModels.Warehouse>> warehouses(SessionIdentity identity, Long uotId);
    PersistenceResult<Long> createWarehouse(SessionIdentity identity, ResourceCommands.CreateWarehouse command);
    PersistenceResult<Void> shareWarehouse(SessionIdentity identity, ResourceCommands.ShareWarehouse command);
    PersistenceResult<List<ResourceModels.Stock>> stock(SessionIdentity identity, Long uotId, Long warehouseId);
    PersistenceResult<List<ResourceModels.Kardex>> kardex(SessionIdentity identity, Long uotId, Long warehouseId, Long productId);
    PersistenceResult<Long> registerMovement(SessionIdentity identity, ResourceCommands.RegisterMovement command);
}
