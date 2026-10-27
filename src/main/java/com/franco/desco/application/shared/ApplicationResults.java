package com.franco.desco.application.shared;

public final class ApplicationResults {

    private ApplicationResults() {
    }

    public static <T> AppResult<T> ok(
            PersistenceResult<T> result,
            String successCode,
            String errorCode,
            AppStatus errorStatus
    ) {
        if (result == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    errorCode,
                    "No se pudo completar la acción en este momento."
            );
        }

        if (result.exitoso()) {
            return AppResult.ok(
                    choose(result.codigo(), successCode),
                    chooseMessage(result.mensaje(), "Acción realizada."),
                    result.datos()
            );
        }

        return AppResult.error(
                AppStatus.fromHttp(
                        result.httpSugerido(),
                        errorStatus
                ),
                choose(result.codigo(), errorCode),
                chooseMessage(
                        result.mensaje(),
                        "No se pudo completar la acción."
                )
        );
    }

    public static <T> AppResult<T> created(
            PersistenceResult<T> result,
            String successCode,
            String errorCode
    ) {
        if (result == null) {
            return AppResult.error(
                    AppStatus.SERVICE_UNAVAILABLE,
                    errorCode,
                    "No se pudo completar la acción en este momento."
            );
        }

        if (result.exitoso()) {
            return AppResult.created(
                    choose(result.codigo(), successCode),
                    chooseMessage(result.mensaje(), "Registro creado."),
                    result.datos()
            );
        }

        return AppResult.error(
                AppStatus.fromHttp(
                        result.httpSugerido(),
                        AppStatus.BAD_REQUEST
                ),
                choose(result.codigo(), errorCode),
                chooseMessage(
                        result.mensaje(),
                        "No se pudo completar el registro."
                )
        );
    }

    private static String choose(
            String preferred,
            String fallback
    ) {
        return preferred == null || preferred.isBlank()
                ? fallback
                : preferred.trim();
    }

    private static String chooseMessage(
            String preferred,
            String fallback
    ) {
        return preferred == null || preferred.isBlank()
                ? fallback
                : preferred.trim();
    }
}
