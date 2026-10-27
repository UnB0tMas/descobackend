package com.franco.desco.application.shared;

public record AppResult<T>(
        boolean exitoso,
        String codigo,
        String mensaje,
        T datos,
        AppStatus estado
) {

    public static <T> AppResult<T> ok(
            String codigo,
            String mensaje,
            T datos
    ) {
        return new AppResult<>(
                true,
                codigo,
                mensaje,
                datos,
                AppStatus.OK
        );
    }

    public static <T> AppResult<T> created(
            String codigo,
            String mensaje,
            T datos
    ) {
        return new AppResult<>(
                true,
                codigo,
                mensaje,
                datos,
                AppStatus.CREATED
        );
    }

    public static <T> AppResult<T> error(
            AppStatus estado,
            String codigo,
            String mensaje
    ) {
        return new AppResult<>(
                false,
                codigo,
                mensaje,
                null,
                estado
        );
    }
}
