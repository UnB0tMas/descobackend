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
        if (result.exitoso()) {
            return AppResult.ok(successCode, result.mensaje(), result.datos());
        }
        return AppResult.error(errorStatus, errorCode, result.mensaje());
    }

    public static <T> AppResult<T> created(
            PersistenceResult<T> result,
            String successCode,
            String errorCode
    ) {
        if (result.exitoso()) {
            return AppResult.created(successCode, result.mensaje(), result.datos());
        }
        return AppResult.error(AppStatus.BAD_REQUEST, errorCode, result.mensaje());
    }
}
