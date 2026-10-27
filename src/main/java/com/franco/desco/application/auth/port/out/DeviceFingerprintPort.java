package com.franco.desco.application.auth.port.out;

import com.franco.desco.application.shared.RequestMetadata;

public interface DeviceFingerprintPort {
    String fingerprint(RequestMetadata metadata);
}
