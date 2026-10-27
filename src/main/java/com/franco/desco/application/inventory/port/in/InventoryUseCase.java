package com.franco.desco.application.inventory.port.in;

import com.franco.desco.application.inventory.InventoryCommands.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.inventory.InventoryModels;

import java.util.List;

public interface InventoryUseCase {

    AppResult<PageResult<InventoryModels.AssetSummary>> listAssets(
            ListAssets command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<InventoryModels.AssetDetail> getAsset(
            GetAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Long> createAsset(
            CreateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> updateAsset(
            UpdateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> retireAsset(
            RetireAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Long> registerVehicle(
            RegisterVehicle command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> updateMileage(
            UpdateMileage command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<PageResult<InventoryModels.Supply>> listSupplies(
            ListSupplies command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Long> createSupply(
            CreateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> updateSupply(
            UpdateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<List<InventoryModels.SupplyMovement>> supplyMovements(
            ListSupplyMovements command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Long> adjustSupply(
            AdjustSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    AppResult<Void> annulSupplyMovement(
            AnnulSupplyMovement command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
