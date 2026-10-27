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
}
