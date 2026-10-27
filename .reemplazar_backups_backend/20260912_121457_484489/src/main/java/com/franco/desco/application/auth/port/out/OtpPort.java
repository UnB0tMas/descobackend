package com.franco.desco.application.auth.port.out;

public interface OtpPort {

    GeneratedOtp generate();

    String hash(String plainCode);

    record GeneratedOtp(
            String code,
            String hmacHex
    ) {
    }
}
