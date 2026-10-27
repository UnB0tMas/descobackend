package com.franco.desco.adapter.out.crypto;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HexFormat;

final class HmacSha256 {

    private HmacSha256() {
    }

    static String hex(
            String base64Secret,
            String value
    ) {
        try {
            byte[] key =
                    Base64.getDecoder()
                            .decode(base64Secret);

            Mac mac =
                    Mac.getInstance("HmacSHA256");

            mac.init(
                    new SecretKeySpec(
                            key,
                            "HmacSHA256"
                    )
            );

            byte[] result =
                    mac.doFinal(
                            (value == null ? "" : value)
                                    .getBytes(StandardCharsets.UTF_8)
                    );

            return HexFormat.of()
                    .formatHex(result);

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo calcular la firma de seguridad.",
                    exception
            );
        }
    }
}
