package com.franco.desco.adapter.out.mail;

import com.franco.desco.infrastructure.config.FrontendProperties;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class SecurityEmailLinkService {

    private final FrontendProperties properties;

    public SecurityEmailLinkService(
            FrontendProperties properties
    ) {
        this.properties = properties;
    }

    public String emailVerification(
            String username
    ) {
        return base("/auth/verificar-cuenta")
                .queryParam(
                        "usuario",
                        username
                )
                .build()
                .encode()
                .toUriString();
    }

    public String twoFactor() {
        return base("/auth/segundo-factor")
                .build()
                .encode()
                .toUriString();
    }

    public String passwordRecovery(
            String username
    ) {
        return base("/auth/restablecer-password")
                .queryParam(
                        "usuario",
                        username
                )
                .build()
                .encode()
                .toUriString();
    }

    public String accountSecurity() {
        return base("/mi-cuenta/seguridad")
                .build()
                .encode()
                .toUriString();
    }

    public String sessions() {
        return base("/mi-cuenta/sesiones")
                .build()
                .encode()
                .toUriString();
    }

    private UriComponentsBuilder base(
            String path
    ) {
        return UriComponentsBuilder
                .fromUriString(
                        properties.baseUrl()
                )
                .path(path);
    }
}
