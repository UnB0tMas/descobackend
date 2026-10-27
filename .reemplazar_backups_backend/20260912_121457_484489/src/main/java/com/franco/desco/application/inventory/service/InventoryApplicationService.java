package com.franco.desco.application.inventory.service;

import com.franco.desco.application.inventory.InventoryCommands.*;
import com.franco.desco.application.inventory.port.in.InventoryUseCase;
import com.franco.desco.application.inventory.port.out.InventoryPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.inventory.InventoryModels;
import java.util.List;

public final class InventoryApplicationService implements InventoryUseCase {
    private final InventoryPersistencePort p;
    public InventoryApplicationService(InventoryPersistencePort p){this.p=p;}
    public AppResult<PageResult<InventoryModels.AssetSummary>> listAssets(ListAssets c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.listAssets(c,i,m),"INVENTARIO_LISTADO","INVENTARIO_NO_LISTADO",AppStatus.BAD_REQUEST);}
    public AppResult<InventoryModels.AssetDetail> getAsset(GetAsset c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.getAsset(c,i,m),"BIEN_OBTENIDO","BIEN_NO_DISPONIBLE",AppStatus.NOT_FOUND);}
    public AppResult<Long> createAsset(CreateAsset c,SessionIdentity i,RequestMetadata m){return ApplicationResults.created(p.createAsset(c,i,m),"BIEN_CREADO","BIEN_NO_CREADO");}
    public AppResult<Void> updateAsset(UpdateAsset c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.updateAsset(c,i,m),"BIEN_ACTUALIZADO","BIEN_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);}
    public AppResult<Void> retireAsset(RetireAsset c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.retireAsset(c,i,m),"BIEN_BAJA","BIEN_NO_BAJA",AppStatus.BAD_REQUEST);}
    public AppResult<Long> registerVehicle(RegisterVehicle c,SessionIdentity i,RequestMetadata m){return ApplicationResults.created(p.registerVehicle(c,i,m),"VEHICULO_REGISTRADO","VEHICULO_NO_REGISTRADO");}
    public AppResult<Void> updateMileage(UpdateMileage c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.updateMileage(c,i,m),"KILOMETRAJE_ACTUALIZADO","KILOMETRAJE_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);}
    public AppResult<PageResult<InventoryModels.Supply>> listSupplies(ListSupplies c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.listSupplies(c,i,m),"SUMINISTROS_LISTADOS","SUMINISTROS_NO_LISTADOS",AppStatus.BAD_REQUEST);}
    public AppResult<Long> createSupply(CreateSupply c,SessionIdentity i,RequestMetadata m){return ApplicationResults.created(p.createSupply(c,i,m),"SUMINISTRO_CREADO","SUMINISTRO_NO_CREADO");}
    public AppResult<Void> updateSupply(UpdateSupply c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.updateSupply(c,i,m),"SUMINISTRO_ACTUALIZADO","SUMINISTRO_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);}
    public AppResult<List<InventoryModels.SupplyMovement>> supplyMovements(ListSupplyMovements c,SessionIdentity i,RequestMetadata m){return ApplicationResults.ok(p.supplyMovements(c,i,m),"KARDEX_OBTENIDO","KARDEX_NO_DISPONIBLE",AppStatus.BAD_REQUEST);}
    public AppResult<Long> adjustSupply(AdjustSupply c,SessionIdentity i,RequestMetadata m){return ApplicationResults.created(p.adjustSupply(c,i,m),"MOVIMIENTO_REGISTRADO","MOVIMIENTO_NO_REGISTRADO");}
}
