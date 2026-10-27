package com.franco.desco.application.resource.service;

import com.franco.desco.application.resource.ResourceCommands;
import com.franco.desco.application.resource.port.in.ResourceUseCase;
import com.franco.desco.application.resource.port.out.ResourcePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ResourceApplicationService implements ResourceUseCase {
    private final ResourcePersistencePort persistence;
    public ResourceApplicationService(ResourcePersistencePort persistence) { this.persistence = persistence; }

    @Override public AppResult<List<ResourceModels.Asset>> assets(SessionIdentity i, Long u) { return ok(persistence.assets(i,u),"BIENES_LISTADOS","BIENES_NO_LISTADOS"); }
    @Override public AppResult<ResourceModels.AssetDetail> asset(SessionIdentity i, Long id) { return ApplicationResults.ok(persistence.asset(i,id),"BIEN_OBTENIDO","BIEN_NO_DISPONIBLE",AppStatus.NOT_FOUND); }
    @Override public AppResult<Long> createAsset(SessionIdentity i, ResourceCommands.CreateAsset c) { return ApplicationResults.created(persistence.createAsset(i,c),"BIEN_CREADO","BIEN_NO_CREADO"); }
    @Override public AppResult<Void> updateAsset(SessionIdentity i, ResourceCommands.UpdateAsset c) { return ok(persistence.updateAsset(i,c),"BIEN_ACTUALIZADO","BIEN_NO_ACTUALIZADO"); }
    @Override public AppResult<Void> changeAssetState(SessionIdentity i, ResourceCommands.ChangeAssetState c) { return ok(persistence.changeAssetState(i,c),"BIEN_ESTADO_ACTUALIZADO","BIEN_ESTADO_NO_ACTUALIZADO"); }
    @Override public AppResult<Long> reportIncident(SessionIdentity i, ResourceCommands.ReportIncident c) { return ApplicationResults.created(persistence.reportIncident(i,c),"INCIDENTE_CREADO","INCIDENTE_NO_CREADO"); }
    @Override public AppResult<List<ResourceModels.Product>> products(SessionIdentity i, Long u) { return ok(persistence.products(i,u),"PRODUCTOS_LISTADOS","PRODUCTOS_NO_LISTADOS"); }
    @Override public AppResult<Long> createProduct(SessionIdentity i, ResourceCommands.CreateProduct c) { return ApplicationResults.created(persistence.createProduct(i,c),"PRODUCTO_CREADO","PRODUCTO_NO_CREADO"); }
    @Override public AppResult<Long> versionPrice(SessionIdentity i, ResourceCommands.VersionPrice c) { return ApplicationResults.created(persistence.versionPrice(i,c),"PRECIO_VERSIONADO","PRECIO_NO_VERSIONADO"); }
    @Override public AppResult<List<ResourceModels.Warehouse>> warehouses(SessionIdentity i, Long u) { return ok(persistence.warehouses(i,u),"ALMACENES_LISTADOS","ALMACENES_NO_LISTADOS"); }
    @Override public AppResult<Long> createWarehouse(SessionIdentity i, ResourceCommands.CreateWarehouse c) { return ApplicationResults.created(persistence.createWarehouse(i,c),"ALMACEN_CREADO","ALMACEN_NO_CREADO"); }
    @Override public AppResult<Void> shareWarehouse(SessionIdentity i, ResourceCommands.ShareWarehouse c) { return ok(persistence.shareWarehouse(i,c),"ALMACEN_COMPARTIDO","ALMACEN_NO_COMPARTIDO"); }
    @Override public AppResult<List<ResourceModels.Stock>> stock(SessionIdentity i, Long u, Long a) { return ok(persistence.stock(i,u,a),"STOCK_LISTADO","STOCK_NO_LISTADO"); }
    @Override public AppResult<List<ResourceModels.Kardex>> kardex(SessionIdentity i, Long u, Long a, Long p) { return ok(persistence.kardex(i,u,a,p),"KARDEX_LISTADO","KARDEX_NO_LISTADO"); }
    @Override public AppResult<Long> registerMovement(SessionIdentity i, ResourceCommands.RegisterMovement c) { return ApplicationResults.created(persistence.registerMovement(i,c),"MOVIMIENTO_CREADO","MOVIMIENTO_NO_CREADO"); }

    private <T> AppResult<T> ok(PersistenceResult<T> result, String success, String error) {
        return ApplicationResults.ok(result, success, error, AppStatus.BAD_REQUEST);
    }
}
