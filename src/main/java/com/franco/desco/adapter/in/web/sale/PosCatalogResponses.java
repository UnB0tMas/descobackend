package com.franco.desco.adapter.in.web.sale;

import com.franco.desco.domain.sale.PosCatalogModels;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.util.List;

public final class PosCatalogResponses {
    private PosCatalogResponses() {}

    @Schema(name = "PosWarehouseOptionResponse")
    public record Warehouse(Long warehouseId, String code, String name) {}

    @Schema(name = "PosCatalogProductResponse")
    public record Product(Long productId, String code, String name, String description, String unit,
                          String category, BigDecimal unitPrice, BigDecimal initialPrice, String currency,
                          BigDecimal stockAvailable, Long imageFileId, String imageUrl) {}

    @Schema(name = "PosCatalogResponse")
    public record Catalog(List<Warehouse> warehouses, List<Product> products) {
        public static Catalog from(PosCatalogModels.Catalog source) {
            return new Catalog(
                    source.warehouses().stream().map(w -> new Warehouse(w.warehouseId(), w.code(), w.name())).toList(),
                    source.products().stream().map(p -> new Product(p.productId(), p.code(), p.name(),
                            p.description(), p.unit(), p.category(), p.unitPrice(), p.initialPrice(),
                            p.currency(), p.stockAvailable(), p.imageFileId(), p.imageUrl())).toList());
        }
    }
}
