package com.franco.desco.domain.auth;

public record Credential(
        Long usuarioId,
        String passwordHash
) {
}
