package com.franco.desco.adapter.out.crypto;

import com.franco.desco.application.auth.port.out.DeviceFingerprintPort;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.stereotype.Component;

@Component
public final class DeviceFingerprintAdapter
        implements DeviceFingerprintPort {

    private final SecurityProperties properties;

    public DeviceFingerprintAdapter(
            SecurityProperties properties
    ) {
        this.properties = properties;
    }

    @Override
    public String fingerprint(
            RequestMetadata metadata
    ) {
        String canonical =
                String.join(
                        "|",
                        safe(metadata.deviceId()),
                        safe(metadata.navegador()),
                        safe(metadata.sistemaOperativo()),
                        safe(metadata.userAgent())
                );

        return HmacSha256.hex(
                properties.deviceHmacSecretBase64(),
                canonical
        );
    }

    private String safe(String value) {
        return value == null
                ? ""
                : value.trim();
    }
}
