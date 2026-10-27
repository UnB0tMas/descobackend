package com.franco.desco.application.auth.port.out;

public interface PasswordHashPort {
    String encode(String rawPassword);
    boolean matches(String rawPassword, String encodedPassword);
    String dummyHash();
}
