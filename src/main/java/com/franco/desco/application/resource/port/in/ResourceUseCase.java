package com.franco.desco.application.resource.port.in;

import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.resource.ResourceModels;

import java.util.List;

public interface ResourceUseCase {
    AppResult<List<ResourceModels.Asset>> assets(SessionIdentity identity, Long uotId);
    AppResult<ResourceModels.AssetDetail> asset(SessionIdentity identity, Long assetId);
    AppResult<Long> createAsset(SessionIdentity identity, ResourceCommands.CreateAsset command);
    AppResult<Void> updateAsset(SessionIdentity identity, ResourceCommands.UpdateAsset command);
    AppResult<Void> changeAssetState(SessionIdentity identity, ResourceCommands.ChangeAssetState command);
    AppResult<Long> reportIncident(SessionIdentity identity, ResourceCommands.ReportIncident command);
    AppResult<List<ResourceModels.Product>> products(SessionIdentity identity, Long uotId);
    AppResult<Long> createProduct(SessionIdentity identity, ResourceCommands.CreateProduct command);
    AppResult<Long> versionPrice(SessionIdentity identity, ResourceCommands.VersionPrice command);
    AppResult<List<ResourceModels.Warehouse>> warehouses(SessionIdentity identity, Long uotId);
    AppResult<Long> createWarehouse(SessionIdentity identity, ResourceCommands.CreateWarehouse command);
    AppResult<Void> shareWarehouse(SessionIdentity identity, ResourceCommands.ShareWarehouse command);
    AppResult<List<ResourceModels.Stock>> stock(SessionIdentity identity, Long uotId, Long warehouseId);
    AppResult<List<ResourceModels.Kardex>> kardex(SessionIdentity identity, Long uotId, Long warehouseId, Long productId);
    AppResult<Long> registerMovement(SessionIdentity identity, ResourceCommands.RegisterMovement command);
}
