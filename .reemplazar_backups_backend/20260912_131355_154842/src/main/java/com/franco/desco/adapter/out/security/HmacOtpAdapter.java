package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.OtpPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

@Component
public class HmacOtpAdapter
        implements OtpPort {

    private static final String HMAC_ALGORITHM =
            "HmacSHA256";

    private final SecureRandom secureRandom =
            new SecureRandom();

    private final byte[] secret;
    private final int digits;

    public HmacOtpAdapter(
            SecurityProperties properties
    ) {
        this.secret = Base64.getDecoder()
                .decode(
                        properties
                                .otpHmacSecretBase64()
                );

        this.digits = properties.otpDigits();
    }

    @Override
    public GeneratedOtp generate() {
        int bound = (int) Math.pow(10, digits);
        int minimum = (int) Math.pow(
                10,
                digits - 1
        );

        int value =
                minimum
                        + secureRandom.nextInt(
                        bound - minimum
                );

        String code = Integer.toString(value);

        return new GeneratedOtp(
                code,
                hash(code)
        );
    }

    @Override
    public String hash(String plainCode) {
        if (plainCode == null) {
            throw new IllegalArgumentException(
                    "El código es obligatorio."
            );
        }

        try {
            Mac mac = Mac.getInstance(
                    HMAC_ALGORITHM
            );

            mac.init(
                    new SecretKeySpec(
                            secret,
                            HMAC_ALGORITHM
                    )
            );

            byte[] result = mac.doFinal(
                    plainCode.trim()
                            .getBytes(
                                    StandardCharsets.UTF_8
                            )
            );

            return HexFormat.of()
                    .formatHex(result);

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No fue posible proteger el código.",
                    exception
            );
        }
    }
}
