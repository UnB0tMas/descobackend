package com.franco.desco.domain.resource;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;

public final class ResourceModels {
    private ResourceModels() {}

    public record Asset(
            Long assetId, Long uotId, String uotCode, String uotName, Integer assetTypeId, String assetType,
            String patrimonialCode, String name, String brand, String model, String serial, String state,
            LocalDate acquisitionDate, BigDecimal acquisitionAmount, String acquisitionCurrency,
            Long providerPersonId, Long providerCompanyId, String observation, Long mainImageFileId,
            int openIncidents, boolean active
    ) {}

    public record AssetHistory(Long historyId, String state, LocalDateTime from, LocalDateTime to, String reason, Long userId) {}
    public record Incident(Long incidentId, String type, LocalDateTime dateTime, String description, BigDecimal estimatedCost,
                           BigDecimal actualCost, String status, Long reporterUserId, LocalDateTime closedAt, String solution) {}
    public record AssetDetail(Asset asset, List<AssetHistory> history, List<Incident> incidents, List<Long> imageFileIds) {}

    public record Product(Long productId, String code, String name, String description, String unit, String category,
                          boolean requiresLot, boolean controlsExpiration, BigDecimal salePrice, String currency,
                          Long priceVersionId, Long mainImageFileId, boolean active) {}

    public record PriceHistory(
            Long priceId, Long productId, String productCode, String product,
            Long uotId, String uotCode, String uotName,
            BigDecimal salePrice, String currency, Integer version,
            LocalDateTime from, LocalDateTime to, boolean current,
            Long userId, String username
    ) {}

    public record Warehouse(Long warehouseId, Long ownerUotId, String ownerUot, Long locationId, String code, String name,
                            String description, String accessType, boolean allowsEntry, boolean allowsExit, boolean active) {}

    public record Stock(Long warehouseId, String warehouse, Long productId, String product, String unit,
                        BigDecimal current, BigDecimal reserved, BigDecimal available, BigDecimal minimum, LocalDateTime updatedAt) {}

    public record Kardex(Long movementId, LocalDateTime dateTime, Long uotId, String uotName, Long warehouseId, String warehouse,
                         String type, String nature, String reference, Long productId, String product, BigDecimal quantity,
                         BigDecimal unitCost, String currency, String lot, LocalDate expirationDate, Long userId, String observation) {}
}
