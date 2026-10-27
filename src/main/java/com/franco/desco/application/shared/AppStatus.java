package com.franco.desco.application.shared;

public enum AppStatus {
    OK,
    CREATED,
    BAD_REQUEST,
    UNAUTHORIZED,
    FORBIDDEN,
    NOT_FOUND,
    CONFLICT,
    TOO_MANY_REQUESTS,
    SERVICE_UNAVAILABLE,
    INTERNAL_ERROR;

    public static AppStatus fromHttp(
            Integer http,
            AppStatus fallback
    ) {
        if (http == null) {
            return fallback;
        }

        return switch (http) {
            case 200, 204 -> OK;
            case 201 -> CREATED;
            case 400, 422 -> BAD_REQUEST;
            case 401 -> UNAUTHORIZED;
            case 403 -> FORBIDDEN;
            case 404 -> NOT_FOUND;
            case 409 -> CONFLICT;
            case 429 -> TOO_MANY_REQUESTS;
            case 503 -> SERVICE_UNAVAILABLE;
            case 500 -> INTERNAL_ERROR;
            default -> fallback;
        };
    }
}
