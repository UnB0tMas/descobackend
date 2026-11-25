package com.franco.desco.application.shared.port.out;

/** Consulta externa de entregabilidad; no confirma la propiedad del buzón. */
@FunctionalInterface
public interface EmailValidationPort {
    enum Result {
        VALID,
        INVALID,
        UNKNOWN
    }

    Result validate(String email);
}
