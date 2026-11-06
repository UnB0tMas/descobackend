package com.franco.desco.application.resource;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import java.util.UUID;

public final class ResourceCommands {
    private ResourceCommands() {}

    public record CreateAsset(Long uotId, Integer assetTypeId, String patrimonialCode, String name, String brand, String model,
                              String serial, LocalDate acquisitionDate, BigDecimal acquisitionAmount, String currency,
                              Long providerPersonId, Long providerCompanyId, String observation, VehicleData vehicle, UUID idempotencyKey) {}
    public record UpdateAsset(Long assetId, Integer assetTypeId, String name, String brand, String model, String serial,
                              LocalDate acquisitionDate, BigDecimal acquisitionAmount, String currency,
                              Long providerPersonId, Long providerCompanyId, String observation, VehicleData vehicle) {}
    public record VehicleData(String plate, String type, BigDecimal mileage, String color) {}
    public record ChangeAssetState(Long assetId, String state, String reason) {}
    public record ReportIncident(Long assetId, String type, LocalDateTime dateTime, String description, BigDecimal estimatedCost, UUID idempotencyKey) {}

    public record CreateProduct(Long contextUotId, String code, String name, String description, String unit, String category, UUID idempotencyKey) {}
    public record VersionPrice(Long contextUotId, Long productId, Long priceUotId, BigDecimal price, String currency, UUID idempotencyKey) {}
    public record CreateWarehouse(Long uotId, Long locationId, String code, String name, String description, UUID idempotencyKey) {}
    public record ShareWarehouse(Long warehouseId, Long uotId, boolean allowsEntry, boolean allowsExit) {}

    public record MovementLine(Long productId, BigDecimal quantity, BigDecimal unitCost, String currency, String lot, LocalDate expirationDate) {}
    public record RegisterMovement(Long uotId, Long warehouseId, String type, String nature, UUID idempotencyKey,
                                   List<MovementLine> lines, Long providerPersonId, Long providerCompanyId,
                                   String documentReference, String observation) {}
}
