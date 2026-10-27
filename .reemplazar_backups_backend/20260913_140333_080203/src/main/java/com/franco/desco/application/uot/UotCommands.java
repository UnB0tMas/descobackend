package com.franco.desco.application.uot;

import java.util.UUID;

public final class UotCommands {
    private UotCommands() {}

    public record SelectContext(String mode, Long uotId) {}

    public record CreateUnit(
            Long parentUotId,
            Long locationId,
            String code,
            String name,
            String description,
            UUID idempotencyKey
    ) {}

    public record UpdateUnit(
            Long uotId,
            Long parentUotId,
            Long locationId,
            String name,
            String description,
            boolean active
    ) {}

    public record AssignUser(
            Long userId,
            Long uotId,
            boolean defaultUnit
    ) {}

    public record AssignRole(
            Long userId,
            Long uotId,
            Long roleId
    ) {}
}
