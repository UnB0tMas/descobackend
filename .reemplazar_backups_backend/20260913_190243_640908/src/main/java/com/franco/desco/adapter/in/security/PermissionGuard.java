package com.franco.desco.adapter.in.security;

import com.franco.desco.application.auth.port.out.AuthorizationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

@Component("permissionGuard")
public class PermissionGuard {
    private final AuthorizationPort authorizationPort;
    private final JwtSessionIdentityResolver identityResolver;
    private final UotAuthorizationService uotAuthorization;

    public PermissionGuard(
            @Qualifier("authSqlServerAdapter") AuthorizationPort authorizationPort,
            JwtSessionIdentityResolver identityResolver,
            UotAuthorizationService uotAuthorization
    ) {
        this.authorizationPort = authorizationPort;
        this.identityResolver = identityResolver;
        this.uotAuthorization = uotAuthorization;
    }

    public boolean has(Authentication authentication, String permissionCode) {
        SessionIdentity identity = identity(authentication);
        return identity != null && authorizationPort.hasPermission(identity, permissionCode);
    }

    public boolean has(String permissionCode) {
        return has(currentAuthentication(), permissionCode);
    }

    public boolean hasUot(Authentication authentication, String permissionCode) {
        SessionIdentity identity = identity(authentication);
        return identity != null && uotAuthorization.hasCurrentPermission(identity, permissionCode);
    }

    public boolean hasUot(String permissionCode) {
        return hasUot(currentAuthentication(), permissionCode);
    }

    public boolean hasUot(Authentication authentication, Long uotId, String permissionCode) {
        SessionIdentity identity = identity(authentication);
        return identity != null && uotAuthorization.hasPermission(identity, uotId, permissionCode);
    }

    public boolean hasUot(Long uotId, String permissionCode) {
        return hasUot(currentAuthentication(), uotId, permissionCode);
    }

    private SessionIdentity identity(Authentication authentication) {
        if (!(authentication instanceof JwtAuthenticationToken jwt) || !jwt.isAuthenticated()) return null;
        try {
            return identityResolver.resolve(jwt);
        } catch (RuntimeException ignored) {
            return null;
        }
    }

    private Authentication currentAuthentication() {
        return org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
    }
}
