package com.franco.desco.adapter.in.security;

import com.franco.desco.application.auth.port.out.AuthorizationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

@Component("permissionGuard")
public class PermissionGuard {

    private final AuthorizationPort authorizationPort;
    private final JwtSessionIdentityResolver identityResolver;

    public PermissionGuard(
            AuthorizationPort authorizationPort,
            JwtSessionIdentityResolver identityResolver
    ) {
        this.authorizationPort = authorizationPort;
        this.identityResolver = identityResolver;
    }

    public boolean has(
            Authentication authentication,
            String permissionCode
    ) {
        if (!(authentication
                instanceof JwtAuthenticationToken jwt)
                || !jwt.isAuthenticated()) {
            return false;
        }

        SessionIdentity identity =
                identityResolver.resolve(jwt);

        return authorizationPort.hasPermission(
                identity,
                permissionCode
        );
    }

    public boolean has(String permissionCode) {
        Authentication authentication =
                org.springframework.security
                        .core.context
                        .SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        return has(
                authentication,
                permissionCode
        );
    }
}
