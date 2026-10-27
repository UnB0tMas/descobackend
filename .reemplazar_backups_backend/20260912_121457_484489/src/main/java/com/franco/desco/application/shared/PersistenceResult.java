package com.franco.desco.application.shared;

public record PersistenceResult<T>(
        boolean exitoso,
        String mensaje,
        T datos
) {
    public static <T> PersistenceResult<T> ok(String mensaje, T datos) {
        return new PersistenceResult<>(true, mensaje, datos);
    }

    public static <T> PersistenceResult<T> error(String mensaje) {
        return new PersistenceResult<>(false, mensaje, null);
    }
}
