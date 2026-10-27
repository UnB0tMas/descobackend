package com.franco.desco.application.inventory.port.out;

import com.franco.desco.application.inventory.InventoryCommands.*;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.inventory.InventoryModels;

import java.util.List;

public interface InventoryPersistencePort {

    PersistenceResult<PageResult<InventoryModels.AssetSummary>> listAssets(
            ListAssets command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<InventoryModels.AssetDetail> getAsset(
            GetAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> createAsset(
            CreateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> updateAsset(
            UpdateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> retireAsset(
            RetireAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> registerVehicle(
            RegisterVehicle command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> updateMileage(
            UpdateMileage command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<PageResult<InventoryModels.Supply>> listSupplies(
            ListSupplies command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> createSupply(
            CreateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> updateSupply(
            UpdateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<List<InventoryModels.SupplyMovement>> supplyMovements(
            ListSupplyMovements command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> adjustSupply(
            AdjustSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> annulSupplyMovement(
            AnnulSupplyMovement command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
