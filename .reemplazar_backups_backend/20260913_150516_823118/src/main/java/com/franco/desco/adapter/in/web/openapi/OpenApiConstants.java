package com.franco.desco.adapter.in.web.openapi;

public final class OpenApiConstants {

    private OpenApiConstants() {
    }

    public static final String BEARER_AUTH =
            "bearerAuth";

    public static final String TAG_AUTH =
            "Autenticación";

    public static final String TAG_AUTH_DESCRIPTION =
            "Inicio de sesión, segundo factor, verificación de correo, recuperación de contraseña, renovación y cierre de sesiones.";

    public static final String HEADER_CORRELATION_ID =
            "X-Correlation-Id";

    public static final String HEADER_DEVICE_ID =
            "X-Device-Id";

    public static final String HEADER_IDEMPOTENCY_KEY =
            "X-Idempotency-Key";

    public static final String AUTH_LOGIN =
            "authLogin";

    public static final String AUTH_REQUEST_TWO_FACTOR =
            "authRequestTwoFactor";

    public static final String AUTH_VERIFY_TWO_FACTOR =
            "authVerifyTwoFactor";

    public static final String AUTH_REQUEST_EMAIL_VERIFICATION =
            "authRequestEmailVerification";

    public static final String AUTH_CONFIRM_EMAIL_VERIFICATION =
            "authConfirmEmailVerification";

    public static final String AUTH_REQUEST_PASSWORD_RECOVERY =
            "authRequestPasswordRecovery";

    public static final String AUTH_RESET_PASSWORD =
            "authResetPassword";

    public static final String AUTH_REFRESH =
            "authRefresh";

    public static final String AUTH_ME =
            "authGetCurrentUser";

    public static final String AUTH_LOGOUT =
            "authLogout";

    public static final String AUTH_LOGOUT_OTHERS =
            "authLogoutOthers";
}
