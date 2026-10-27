package com.franco.desco.adapter.in.security;

import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import org.springframework.stereotype.Component;

@Component
public class UotAuthorizationService {
    private final UotPersistencePort persistence;

    public UotAuthorizationService(UotPersistencePort persistence) {
        this.persistence = persistence;
    }

    public boolean hasCurrentPermission(SessionIdentity identity, String permissionCode) {
        if (identity == null || permissionCode == null || permissionCode.isBlank()) return false;
        return persistence.hasPermission(identity, permissionCode.trim().toUpperCase());
    }

    public boolean hasPermission(SessionIdentity identity, Long uotId, String permissionCode) {
        if (identity == null || uotId == null || permissionCode == null || permissionCode.isBlank()) return false;
        return persistence.hasPermission(identity, uotId, permissionCode.trim().toUpperCase());
    }

    public boolean hasAccess(SessionIdentity identity, Long uotId) {
        return identity != null && uotId != null && persistence.hasAccess(identity, uotId);
    }
}
