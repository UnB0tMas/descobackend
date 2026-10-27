package com.franco.desco.application.shared.port.out;

public interface RequestHashPort {
    String sha256Hex(String value);
}
