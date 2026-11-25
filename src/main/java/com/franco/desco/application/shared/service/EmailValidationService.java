package com.franco.desco.application.shared.service;

import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.port.out.EmailValidationPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.regex.Pattern;

/** Control previo a persistencia. Independiente de SMTP y de los PA. */
@Service
public final class EmailValidationService {
    private static final Pattern SIMPLE_EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private final EmailValidationPort provider;
    private final boolean enabled;

    public EmailValidationService(
            EmailValidationPort provider,
            @Value("${app.email-validation.enabled:false}") boolean enabled
    ) {
        this.provider = provider;
        this.enabled = enabled;
    }

    /** Null significa que puede continuar; de lo contrario devuelve el error público. */
    public <T> AppResult<T> required(String email) {
        if (!enabled) {
            return null;
        }
        if (email == null || email.isBlank()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CORREO_REQUERIDO",
                    "Ingrese un correo electrónico real para continuar.");
        }
        return check(email);
    }

    /** En modificaciones parciales, un correo no enviado no cambia el existente. */
    public <T> AppResult<T> ifProvided(String email) {
        if (!enabled || email == null) {
            return null;
        }
        if (email.isBlank()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CORREO_REQUERIDO",
                    "Ingrese un correo electrónico real para continuar.");
        }
        return check(email);
    }

    private <T> AppResult<T> check(String email) {
        String normalized = email.trim().toLowerCase(Locale.ROOT);
        if (normalized.length() > 254 || !SIMPLE_EMAIL.matcher(normalized).matches()) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CORREO_NO_VALIDO",
                    "Ingrese un correo electrónico real para continuar.");
        }
        EmailValidationPort.Result result = provider.validate(normalized);
        if (result == EmailValidationPort.Result.VALID) {
            return null;
        }
        if (result == EmailValidationPort.Result.INVALID) {
            return AppResult.error(AppStatus.BAD_REQUEST, "CORREO_NO_NOTIFICABLE",
                    "El correo no puede recibir mensajes. Ingrese otro correo.");
        }
        return AppResult.error(AppStatus.SERVICE_UNAVAILABLE, "CORREO_VERIFICACION_NO_DISPONIBLE",
                "No se pudo verificar el correo. Intente nuevamente.");
    }
}
