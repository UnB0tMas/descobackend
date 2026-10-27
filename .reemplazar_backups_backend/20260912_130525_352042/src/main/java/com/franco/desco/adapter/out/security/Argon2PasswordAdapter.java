package com.franco.desco.adapter.out.security;

import com.franco.desco.application.auth.port.out.PasswordHashPort;
import com.franco.desco.infrastructure.config.SecurityProperties;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class Argon2PasswordAdapter
        implements PasswordHashPort {

    private final PasswordEncoder passwordEncoder;
    private final SecurityProperties properties;

    public Argon2PasswordAdapter(
            PasswordEncoder passwordEncoder,
            SecurityProperties properties
    ) {
        this.passwordEncoder = passwordEncoder;
        this.properties = properties;
    }

    @Override
    public boolean matches(
            String rawPassword,
            String encodedPassword
    ) {
        return passwordEncoder.matches(
                rawPassword,
                encodedPassword
        );
    }

    @Override
    public String encode(String rawPassword) {
        return passwordEncoder.encode(rawPassword);
    }

    @Override
    public String dummyHash() {
        return properties.dummyPasswordHash();
    }
}
