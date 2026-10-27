package com.franco.desco.application.shared.port.out;

@FunctionalInterface
public interface RequestHashPort {

    String sha256Hex(String value);
}
