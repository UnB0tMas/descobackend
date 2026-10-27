package com.franco.desco.adapter.out.sqlserver.inventory;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.inventory.*;
import com.franco.desco.application.inventory.InventoryCommands.*;
import com.franco.desco.application.inventory.port.out.InventoryPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.inventory.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class InventorySqlServerAdapter
        extends JsonPaAdapterSupport
        implements InventoryPersistencePort {

    public InventorySqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<InventoryModels.AssetSummary>> listAssets(ListAssets c,SessionIdentity i,RequestMetadata m) {
        return page("logistica.PA_BienInventario_Sel_Listado", c, i, m, InventoryModels.AssetSummary.class);
    }

    @Override
    public PersistenceResult<InventoryModels.AssetDetail> getAsset(GetAsset c,SessionIdentity i,RequestMetadata m) {
        return one("logistica.PA_BienInventario_Sel_Detalle", c, i, m, InventoryModels.AssetDetail.class);
    }

    @Override
    public PersistenceResult<Long> createAsset(CreateAsset c,SessionIdentity i,RequestMetadata m) {
        return create("logistica.PA_BienInventario_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateAsset(UpdateAsset c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_BienInventario_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> retireAsset(RetireAsset c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_BienInventario_Upd_Baja", c, i, m);
    }

    @Override
    public PersistenceResult<Long> registerVehicle(RegisterVehicle c,SessionIdentity i,RequestMetadata m) {
        return create("logistica.PA_Vehiculo_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateMileage(UpdateMileage c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_Vehiculo_Upd_Kilometraje", c, i, m);
    }

    @Override
    public PersistenceResult<PageResult<InventoryModels.Supply>> listSupplies(ListSupplies c,SessionIdentity i,RequestMetadata m) {
        return page("logistica.PA_Suministro_Sel_Listado", c, i, m, InventoryModels.Supply.class);
    }

    @Override
    public PersistenceResult<Long> createSupply(CreateSupply c,SessionIdentity i,RequestMetadata m) {
        return create("logistica.PA_Suministro_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateSupply(UpdateSupply c,SessionIdentity i,RequestMetadata m) {
        return mutate("logistica.PA_Suministro_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<List<InventoryModels.SupplyMovement>> supplyMovements(ListSupplyMovements c,SessionIdentity i,RequestMetadata m) {
        return list("logistica.PA_SuministroMovimiento_Sel_Kardex", c, i, m, InventoryModels.SupplyMovement.class);
    }

    @Override
    public PersistenceResult<Long> adjustSupply(AdjustSupply c,SessionIdentity i,RequestMetadata m) {
        return create("logistica.PA_SuministroMovimiento_Ins_Ajuste", c, i, m);
    }

    @Override
    public PersistenceResult<Void> annulSupplyMovement(
            AnnulSupplyMovement c,
            SessionIdentity i,
            RequestMetadata m
    ) {
        return mutate(
                "logistica.PA_SuministroMovimiento_Upd_Anular",
                c,
                i,
                m
        );
    }

}
