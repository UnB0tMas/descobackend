package com.franco.desco.domain.uot;

import java.util.ArrayList;
import java.util.List;

public final class UotLifecycleModels {
    private UotLifecycleModels() {}

    public record DeactivationImpact(
            Long uotId,
            int includedUots,
            int activeUsers,
            int exclusiveUsers,
            int activeEmployees,
            int activeAreas,
            int activeOrganizations,
            int activeProperties,
            int activeWarehouses,
            int productsWithStock,
            int reservedStockRows,
            int suppliesWithStock,
            int reservedSupplies,
            int activeAssets,
            int openSales,
            int openCampaigns,
            int openOperations,
            int openFieldTrips,
            int openResources,
            boolean canDeactivate
    ) {
        public List<String> blockers() {
            List<String> values = new ArrayList<>();
            if (productsWithStock > 0) values.add("Hay stock de productos por transferir.");
            if (reservedStockRows > 0) values.add("Hay stock de productos reservado.");
            if (suppliesWithStock > 0) values.add("Hay suministros por transferir.");
            if (reservedSupplies > 0) values.add("Hay suministros reservados.");
            if (activeAssets > 0) values.add("Hay bienes por transferir o retirar.");
            if (openSales > 0) values.add("Hay ventas pendientes.");
            if (openCampaigns > 0) values.add("Hay campañas pendientes.");
            if (openOperations > 0) values.add("Hay operativos pendientes.");
            if (openFieldTrips > 0) values.add("Hay salidas pendientes.");
            if (openResources > 0) values.add("Hay recursos programados pendientes.");
            return List.copyOf(values);
        }
    }

    public record ResourceTransfer(
            Long sourceMovementId,
            Long targetMovementId,
            int transferredProducts,
            int transferredAssets,
            int transferredSupplies
    ) {}
}
