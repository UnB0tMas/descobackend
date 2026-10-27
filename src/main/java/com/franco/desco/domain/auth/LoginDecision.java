package com.franco.desco.domain.auth;

public record LoginDecision(
        String pasoSiguiente,
        boolean requiereSegundoFactor,
        boolean exitoso,
        String mensaje
) {
}
