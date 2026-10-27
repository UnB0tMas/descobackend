package com.franco.desco.application.auth.port.out;

import com.franco.desco.application.shared.SessionIdentity;

public interface AuthorizationPort {
    boolean hasPermission(
            SessionIdentity identity,
            String permissionCode
    );
}
