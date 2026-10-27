package com.franco.desco.adapter.out.crypto;

import com.franco.desco.application.auth.port.out.PasswordHashPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public final class PasswordHashAdapter
        implements PasswordHashPort {

    private final PasswordEncoder passwordEncoder;
    private final SecurityProperties properties;

    public PasswordHashAdapter(
            PasswordEncoder passwordEncoder,
            SecurityProperties properties
    ) {
        this.passwordEncoder = passwordEncoder;
        this.properties = properties;
    }

    @Override
    public String encode(String rawPassword) {
        if (rawPassword == null
                || rawPassword.isBlank()) {
            throw new IllegalArgumentException(
                    "La contraseña no es válida."
            );
        }

        return passwordEncoder.encode(rawPassword);
    }

    @Override
    public boolean matches(
            String rawPassword,
            String encodedPassword
    ) {
        if (rawPassword == null
                || encodedPassword == null
                || encodedPassword.isBlank()) {
            return false;
        }

        try {
            return passwordEncoder.matches(
                    rawPassword,
                    encodedPassword
            );
        } catch (RuntimeException exception) {
            return false;
        }
    }

    @Override
    public String dummyHash() {
        return properties.dummyPasswordHash();
    }
}
