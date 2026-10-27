package com.franco.desco.application.inventory.service;

import com.franco.desco.application.inventory.InventoryCommands.*;
import com.franco.desco.application.inventory.port.in.InventoryUseCase;
import com.franco.desco.application.inventory.port.out.InventoryPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.inventory.InventoryModels;

import java.util.List;

public final class InventoryApplicationService
        implements InventoryUseCase {

    private final InventoryPersistencePort persistence;

    public InventoryApplicationService(
            InventoryPersistencePort persistence
    ) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<PageResult<InventoryModels.AssetSummary>> listAssets(
            ListAssets command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.listAssets(command, identity, metadata),
                "INVENTARIO_LISTADO",
                "INVENTARIO_NO_LISTADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<InventoryModels.AssetDetail> getAsset(
            GetAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.getAsset(command, identity, metadata),
                "BIEN_OBTENIDO",
                "BIEN_NO_DISPONIBLE",
                AppStatus.NOT_FOUND
        );
    }

    @Override
    public AppResult<Long> createAsset(
            CreateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.createAsset(command, identity, metadata),
                "BIEN_CREADO",
                "BIEN_NO_CREADO"
        );
    }

    @Override
    public AppResult<Void> updateAsset(
            UpdateAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.updateAsset(command, identity, metadata),
                "BIEN_ACTUALIZADO",
                "BIEN_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Void> retireAsset(
            RetireAsset command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.retireAsset(command, identity, metadata),
                "BIEN_BAJA",
                "BIEN_NO_BAJA",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Long> registerVehicle(
            RegisterVehicle command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.registerVehicle(command, identity, metadata),
                "VEHICULO_REGISTRADO",
                "VEHICULO_NO_REGISTRADO"
        );
    }

    @Override
    public AppResult<Void> updateMileage(
            UpdateMileage command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.updateMileage(command, identity, metadata),
                "KILOMETRAJE_ACTUALIZADO",
                "KILOMETRAJE_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<PageResult<InventoryModels.Supply>> listSupplies(
            ListSupplies command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.listSupplies(command, identity, metadata),
                "SUMINISTROS_LISTADOS",
                "SUMINISTROS_NO_LISTADOS",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Long> createSupply(
            CreateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.createSupply(command, identity, metadata),
                "SUMINISTRO_CREADO",
                "SUMINISTRO_NO_CREADO"
        );
    }

    @Override
    public AppResult<Void> updateSupply(
            UpdateSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.updateSupply(command, identity, metadata),
                "SUMINISTRO_ACTUALIZADO",
                "SUMINISTRO_NO_ACTUALIZADO",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<List<InventoryModels.SupplyMovement>> supplyMovements(
            ListSupplyMovements command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.supplyMovements(command, identity, metadata),
                "KARDEX_OBTENIDO",
                "KARDEX_NO_DISPONIBLE",
                AppStatus.BAD_REQUEST
        );
    }

    @Override
    public AppResult<Long> adjustSupply(
            AdjustSupply command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.created(
                persistence.adjustSupply(command, identity, metadata),
                "MOVIMIENTO_REGISTRADO",
                "MOVIMIENTO_NO_REGISTRADO"
        );
    }

    @Override
    public AppResult<Void> annulSupplyMovement(
            AnnulSupplyMovement command,
            SessionIdentity identity,
            RequestMetadata metadata
    ) {
        return ApplicationResults.ok(
                persistence.annulSupplyMovement(command, identity, metadata),
                "MOVIMIENTO_ANULADO",
                "MOVIMIENTO_NO_ANULADO",
                AppStatus.BAD_REQUEST
        );
    }
}
