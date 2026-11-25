package com.franco.desco.domain.sale;

import java.math.BigDecimal;
import java.util.List;

public final class PosCatalogModels {
    private PosCatalogModels() {}

    public record Warehouse(Long warehouseId, String code, String name) {}

    public record Product(Long productId, String code, String name, String description,
                          String unit, String category, BigDecimal unitPrice, BigDecimal initialPrice,
                          String currency, BigDecimal stockAvailable, Long imageFileId, String imageUrl) {}

    public record Catalog(List<Warehouse> warehouses, List<Product> products) {}
}
