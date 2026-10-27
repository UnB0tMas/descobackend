package com.franco.desco.application.auth.port.out;

public interface PasswordHashPort {

    boolean matches(String rawPassword, String encodedPassword);

    String encode(String rawPassword);

    String dummyHash();
}
