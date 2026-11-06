package com.franco.desco.domain.resource;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class ResourceModels {

    private ResourceModels() {
    }

    public record Asset(
            Long assetId,
            Long uotId,
            String uotCode,
            String uotName,
            Integer assetTypeId,
            String assetType,
            String patrimonialCode,
            String name,
            String brand,
            String model,
            String serial,
            String state,
            LocalDate acquisitionDate,
            BigDecimal acquisitionAmount,
            String acquisitionCurrency,
            Long providerPersonId,
            Long providerCompanyId,
            String observation,
            Long mainImageFileId,
            int openIncidents,
            boolean active
    ) {
    }

    public record AssetListItem(
            Long assetId,
            Long uotId,
            String uotCode,
            String uotName,
            Integer assetTypeId,
            String assetTypeCode,
            String assetType,
            String patrimonialCode,
            String name,
            String brand,
            String model,
            String serial,
            String state,
            LocalDate acquisitionDate,
            BigDecimal acquisitionAmount,
            String acquisitionCurrency,
            Long providerPersonId,
            Long providerCompanyId,
            String providerName,
            String observation,
            String plate,
            String vehicleType,
            BigDecimal mileageKm,
            String color,
            Long mainImageFileId,
            int openIncidents,
            boolean active,
            long totalRecords
    ) {
    }

    public record AssetHistory(
            Long historyId,
            String state,
            LocalDateTime from,
            LocalDateTime to,
            String reason,
            Long userId
    ) {
    }

    public record Incident(
            Long incidentId,
            String type,
            LocalDateTime dateTime,
            String description,
            BigDecimal estimatedCost,
            BigDecimal actualCost,
            String status,
            Long reporterUserId,
            LocalDateTime closedAt,
            String solution
    ) {
    }

    public record AssetDetail(
            Asset asset,
            List<AssetHistory> history,
            List<Incident> incidents,
            List<Long> imageFileIds
    ) {
    }

    public record Product(
            Long productId,
            String code,
            String name,
            String description,
            String unit,
            String category,
            boolean requiresLot,
            boolean controlsExpiration,
            BigDecimal salePrice,
            String currency,
            Long priceVersionId,
            Long mainImageFileId,
            boolean active
    ) {
    }

    public record ProductListItem(
            Long productId,
            Long uotId,
            String uotCode,
            String uotName,
            String code,
            String name,
            String description,
            String unitCode,
            String unitName,
            String categoryCode,
            String categoryName,
            boolean requiresLot,
            boolean controlsExpiration,
            boolean allowsSale,
            BigDecimal initialPrice,
            BigDecimal currentPrice,
            String currency,
            Long currentPriceId,
            Integer currentPriceVersion,
            Long mainImageFileId,
            boolean active,
            long totalRecords
    ) {
    }

    public record ProductDetail(
            Long productId,
            Long uotId,
            String uotCode,
            String uotName,
            String code,
            String name,
            String description,
            String unitCode,
            String unitName,
            String categoryCode,
            String categoryName,
            boolean requiresLot,
            boolean controlsExpiration,
            boolean allowsSale,
            BigDecimal initialPrice,
            BigDecimal currentPrice,
            String currency,
            Long currentPriceId,
            Integer currentPriceVersion,
            Long mainImageFileId,
            List<Long> imageFileIds,
            boolean active
    ) {
    }

    public record PriceHistory(
            Long priceId,
            Long productId,
            String productCode,
            String product,
            Long uotId,
            String uotCode,
            String uotName,
            BigDecimal initialPrice,
            BigDecimal salePrice,
            String currency,
            Integer version,
            LocalDateTime from,
            LocalDateTime to,
            boolean current,
            Long userId,
            String username,
            Long originPriceId,
            Integer originVersion
    ) {
    }

    public record PriceReactivation(
            Long priceId,
            Integer version,
            Long originPriceId
    ) {
    }

    public record Warehouse(
            Long warehouseId,
            Long ownerUotId,
            String ownerUot,
            Long locationId,
            String code,
            String name,
            String description,
            String accessType,
            boolean allowsEntry,
            boolean allowsExit,
            boolean active
    ) {
    }

    public record Stock(
            Long warehouseId,
            String warehouse,
            Long productId,
            String product,
            String unit,
            BigDecimal current,
            BigDecimal reserved,
            BigDecimal available,
            BigDecimal minimum,
            LocalDateTime updatedAt,
            boolean active,
            boolean hasHistory
    ) {
        // Compatibilidad con adaptadores que todavia construyen Stock con 11 argumentos.
        // Si el adaptador antiguo no informa historial, se asume que existe por seguridad.
        // La fuente real debe venir del adaptador SQL para recuperar la operacion RETIRAR.
        public Stock(
                Long warehouseId,
                String warehouse,
                Long productId,
                String product,
                String unit,
                BigDecimal current,
                BigDecimal reserved,
                BigDecimal available,
                BigDecimal minimum,
                LocalDateTime updatedAt,
                boolean active
        ) {
            this(warehouseId, warehouse, productId, product, unit,
                    current, reserved, available, minimum, updatedAt, active, true);
        }

        /**
         * Firma legada del adaptador de recursos SQL (10 argumentos).
         * No se pueden recuperar estado ni historial desde los diez valores.
         * Se mantiene el producto visible y, por seguridad, se considera
         * que existe historial para no autorizar retiros sin verificarlo.
         * El adaptador SQL debe migrar a la firma de 12 argumentos y
         * proporcionar los dos indicadores reales de la base de datos.
         */
        public Stock(
                Long warehouseId,
                String warehouse,
                Long productId,
                String product,
                String unit,
                BigDecimal current,
                BigDecimal reserved,
                BigDecimal available,
                BigDecimal minimum,
                LocalDateTime updatedAt
        ) {
            this(warehouseId, warehouse, productId, product, unit,
                    current, reserved, available, minimum, updatedAt, true, true);
        }
    }

    public record Kardex(
            Long movementId,
            LocalDateTime dateTime,
            Long uotId,
            String uotName,
            Long warehouseId,
            String warehouse,
            String type,
            String nature,
            String reference,
            Long productId,
            String product,
            BigDecimal quantity,
            BigDecimal unitCost,
            String currency,
            String lot,
            LocalDate expirationDate,
            Long userId,
            String observation
    ) {
    }

    public record CodeSuggestion(
            Long uotId,
            String type,
            String code
    ) {
    }

    public record WarehouseProductConfiguration(
            Long warehouseId,
            Long productId,
            Long movementId,
            BigDecimal currentStock,
            BigDecimal minimumStock
    ) {
    }
}
