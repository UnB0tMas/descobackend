package com.franco.desco.application.auth.port.out;

import com.franco.desco.application.shared.SessionIdentity;

public interface SessionValidationPort {
    boolean isValid(
            SessionIdentity identity,
            String jtiHashHex,
            String ip
    );
}
