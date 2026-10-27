package com.franco.desco.domain.uot;

import java.time.LocalDate;
import java.util.List;

public final class UotModels {
    private UotModels() {}

    public record Unit(
            Long uotId,
            Long parentUotId,
            Long locationId,
            String code,
            String name,
            String description,
            boolean root,
            LocalDate startDate,
            LocalDate endDate,
            boolean active,
            boolean assigned,
            boolean defaultUnit
    ) {}

    public record Membership(
            Long userUotId,
            Long uotId,
            String code,
            String name,
            boolean defaultUnit,
            List<String> roles
    ) {
        public Membership {
            roles = roles == null ? List.of() : List.copyOf(roles);
        }
    }

    public record Context(
            String mode,
            Long selectedUotId,
            boolean selectionRequired,
            boolean generalModeAllowed,
            List<Membership> memberships
    ) {
        public Context {
            memberships = memberships == null ? List.of() : List.copyOf(memberships);
        }
    }
}
