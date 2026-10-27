package com.franco.desco.adapter.out.crypto;

import com.franco.desco.application.auth.port.out.OtpPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;

@Component
@Primary
public final class OtpAdapter implements OtpPort {

    private final SecurityProperties properties;
    private final SecureRandom random =
            new SecureRandom();

    public OtpAdapter(
            SecurityProperties properties
    ) {
        this.properties = properties;
    }

    @Override
    public GeneratedOtp generate() {
        int digits =
                Math.max(
                        6,
                        Math.min(
                                8,
                                properties.otpDigits()
                        )
                );

        int bound =
                (int) Math.pow(10, digits);

        int floor =
                (int) Math.pow(
                        10,
                        digits - 1
                );

        int value =
                floor
                        + random.nextInt(
                        bound - floor
                );

        String code =
                Integer.toString(value);

        return new GeneratedOtp(
                code,
                hash(code)
        );
    }

    @Override
    public String hash(String code) {
        return HmacSha256.hex(
                properties.otpHmacSecretBase64(),
                code == null ? "" : code.trim()
        );
    }
}
