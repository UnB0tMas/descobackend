package com.franco.desco.application.uot;

import java.util.List;
import java.util.UUID;

public final class UotLifecycleCommands {
    private UotLifecycleCommands() {}

    public record Impact(Long uotId) {}
    public record Deactivate(Long uotId, String reason) {}
    public record TransferResources(
            Long sourceUotId,
            Long targetUotId,
            Long sourceWarehouseId,
            Long targetWarehouseId,
            boolean transferStock,
            List<Long> assetIds,
            List<Long> supplyIds,
            String reason,
            UUID idempotencyKey
    ) {
        public TransferResources {
            assetIds = assetIds == null ? List.of() : List.copyOf(assetIds);
            supplyIds = supplyIds == null ? List.of() : List.copyOf(supplyIds);
        }
    }
}
