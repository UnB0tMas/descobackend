package com.franco.desco.adapter.in.web.resource;

import com.franco.desco.domain.resource.ResourceModels;
import org.springframework.stereotype.Component;

@Component
public class ResourceWebMapper {

    public ResourceResponses.Asset response(ResourceModels.Asset value) {
        return new ResourceResponses.Asset(
                value.assetId(), value.uotId(), value.uotCode(), value.uotName(),
                value.assetTypeId(), value.assetType(), value.patrimonialCode(), value.name(),
                value.brand(), value.model(), value.serial(), value.state(), value.acquisitionDate(),
                value.acquisitionAmount(), value.acquisitionCurrency(), value.providerPersonId(),
                value.providerCompanyId(), value.observation(), value.mainImageFileId(),
                value.openIncidents(), value.active()
        );
    }

    public ResourceResponses.AssetListItem response(ResourceModels.AssetListItem value) {
        return new ResourceResponses.AssetListItem(
                value.assetId(), value.uotId(), value.uotCode(), value.uotName(),
                value.assetTypeId(), value.assetTypeCode(), value.assetType(), value.patrimonialCode(),
                value.name(), value.brand(), value.model(), value.serial(), value.state(),
                value.acquisitionDate(), value.acquisitionAmount(), value.acquisitionCurrency(),
                value.providerPersonId(), value.providerCompanyId(), value.providerName(), value.observation(),
                value.plate(), value.vehicleType(), value.mileageKm(), value.mainImageFileId(),
                contentUrl(value.mainImageFileId()), value.openIncidents(), value.active()
        );
    }

    public ResourceResponses.AssetHistory response(ResourceModels.AssetHistory value) {
        return new ResourceResponses.AssetHistory(
                value.historyId(), value.state(), value.from(), value.to(), value.reason(), value.userId()
        );
    }

    public ResourceResponses.AssetIncident response(ResourceModels.Incident value) {
        return new ResourceResponses.AssetIncident(
                value.incidentId(), value.type(), value.dateTime(), value.description(), value.estimatedCost(),
                value.actualCost(), value.status(), value.reporterUserId(), value.closedAt(), value.solution()
        );
    }

    public ResourceResponses.AssetDetail response(ResourceModels.AssetDetail value) {
        return new ResourceResponses.AssetDetail(
                response(value.asset()),
                value.history().stream().map(this::response).toList(),
                value.incidents().stream().map(this::response).toList(),
                value.imageFileIds()
        );
    }

    public ResourceResponses.Product response(ResourceModels.Product value) {
        return new ResourceResponses.Product(
                value.productId(), value.code(), value.name(), value.description(), value.unit(), value.category(),
                value.requiresLot(), value.controlsExpiration(), value.salePrice(), value.currency(),
                value.priceVersionId(), value.mainImageFileId(), value.active()
        );
    }

    public ResourceResponses.ProductListItem response(ResourceModels.ProductListItem value) {
        return new ResourceResponses.ProductListItem(
                value.productId(), value.uotId(), value.uotCode(), value.uotName(), value.code(), value.name(),
                value.description(), value.unitCode(), value.unitName(), value.categoryCode(), value.categoryName(),
                value.requiresLot(), value.controlsExpiration(), value.allowsSale(), value.initialPrice(), value.currentPrice(), value.currency(),
                value.currentPriceId(), value.currentPriceVersion(), value.mainImageFileId(),
                contentUrl(value.mainImageFileId()), value.active()
        );
    }

    public ResourceResponses.ProductDetail response(ResourceModels.ProductDetail value) {
        return new ResourceResponses.ProductDetail(
                value.productId(), value.uotId(), value.uotCode(), value.uotName(), value.code(), value.name(),
                value.description(), value.unitCode(), value.unitName(), value.categoryCode(), value.categoryName(),
                value.requiresLot(), value.controlsExpiration(), value.allowsSale(), value.initialPrice(), value.currentPrice(), value.currency(),
                value.currentPriceId(), value.currentPriceVersion(), value.mainImageFileId(),
                contentUrl(value.mainImageFileId()), value.imageFileIds(), value.active()
        );
    }

    public ResourceResponses.PriceHistory response(ResourceModels.PriceHistory value) {
        return new ResourceResponses.PriceHistory(
                value.priceId(), value.productId(), value.productCode(), value.product(),
                value.uotId(), value.uotCode(), value.uotName(), value.initialPrice(), value.salePrice(), value.currency(),
                value.version(), value.from(), value.to(), value.current(), value.userId(), value.username(),
                value.originPriceId(), value.originVersion()
        );
    }

    public ResourceResponses.PriceReactivated response(ResourceModels.PriceReactivation value) {
        return new ResourceResponses.PriceReactivated(
                value.priceId(), value.version(), value.originPriceId()
        );
    }

    public ResourceResponses.Warehouse response(ResourceModels.Warehouse value) {
        return new ResourceResponses.Warehouse(
                value.warehouseId(), value.ownerUotId(), value.ownerUot(), value.locationId(), value.code(),
                value.name(), value.description(), value.accessType(), value.allowsEntry(), value.allowsExit(), value.active()
        );
    }

    public ResourceResponses.Stock response(ResourceModels.Stock value) {
        return new ResourceResponses.Stock(
                value.warehouseId(), value.warehouse(), value.productId(), value.product(), value.unit(),
                value.current(), value.reserved(), value.available(), value.minimum(), value.updatedAt()
        );
    }

    public ResourceResponses.Kardex response(ResourceModels.Kardex value) {
        return new ResourceResponses.Kardex(
                value.movementId(), value.dateTime(), value.uotId(), value.uotName(), value.warehouseId(), value.warehouse(),
                value.type(), value.nature(), value.reference(), value.productId(), value.product(), value.quantity(),
                value.unitCost(), value.currency(), value.lot(), value.expirationDate(), value.userId(), value.observation()
        );
    }

    public ResourceResponses.CodeSuggestion response(ResourceModels.CodeSuggestion value) {
        return new ResourceResponses.CodeSuggestion(
                value.uotId(), value.type(), value.code()
        );
    }

    public ResourceResponses.WarehouseProductConfigured response(
            ResourceModels.WarehouseProductConfiguration value
    ) {
        return new ResourceResponses.WarehouseProductConfigured(
                value.warehouseId(), value.productId(), value.movementId(),
                value.currentStock(), value.minimumStock()
        );
    }

    private static String contentUrl(Long fileId) {
        return fileId == null ? null : "/api/v1/documentos/local/" + fileId + "/contenido";
    }
}
