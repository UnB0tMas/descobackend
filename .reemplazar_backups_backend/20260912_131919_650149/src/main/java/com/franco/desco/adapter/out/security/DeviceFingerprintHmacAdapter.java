package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.DeviceFingerprintPort;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HexFormat;

@Component
public class DeviceFingerprintHmacAdapter
        implements DeviceFingerprintPort {

    private static final String ALGORITHM =
            "HmacSHA256";

    private final byte[] secret;

    public DeviceFingerprintHmacAdapter(
            SecurityProperties properties
    ) {
        this.secret = Base64.getDecoder()
                .decode(
                        properties
                                .deviceHmacSecretBase64()
                );
    }

    @Override
    public String fingerprint(
            RequestMetadata metadata
    ) {
        String material = String.join(
                "|",
                safe(metadata.deviceId()),
                safe(metadata.userAgent()),
                safe(metadata.navegador()),
                safe(metadata.sistemaOperativo())
        );

        try {
            Mac mac = Mac.getInstance(ALGORITHM);

            mac.init(
                    new SecretKeySpec(
                            secret,
                            ALGORITHM
                    )
            );

            return HexFormat.of()
                    .formatHex(
                            mac.doFinal(
                                    material.getBytes(
                                            StandardCharsets.UTF_8
                                    )
                            )
                    );

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No fue posible identificar el dispositivo.",
                    exception
            );
        }
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}
