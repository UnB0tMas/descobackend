package com.franco.desco.adapter.out.crypto;

import com.franco.desco.application.shared.port.out.RequestHashPort;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

@Component
public final class Sha256RequestHashAdapter
        implements RequestHashPort {

    public String sha256Hex(String value) {
        try {
            MessageDigest digest =
                    MessageDigest.getInstance("SHA-256");

            byte[] hash =
                    digest.digest(
                            (value == null ? "" : value)
                                    .getBytes(StandardCharsets.UTF_8)
                    );

            return HexFormat.of()
                    .formatHex(hash);

        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(
                    "SHA-256 no está disponible.",
                    exception
            );
        }
    }
}
