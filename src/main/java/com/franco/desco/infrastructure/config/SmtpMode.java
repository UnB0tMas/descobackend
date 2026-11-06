package com.franco.desco.infrastructure.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;

import java.util.Arrays;
import java.util.Locale;
import java.util.regex.Pattern;

public record SmtpMode(boolean enabled, boolean devAutoVerifyOtp) {
    private static final Logger LOG = LoggerFactory.getLogger(SmtpMode.class);
    private static final Pattern LOCAL_SQL_SERVER = Pattern.compile(
            "^jdbc:sqlserver://(?:localhost|127\\.0\\.0\\.1)(?::[0-9]+)?(?:;|$)",
            Pattern.CASE_INSENSITIVE);

    public static SmtpMode from(Environment environment) {
        boolean enabled = readBoolean(environment, "app.smtp.enabled", false);
        boolean requested = readBoolean(environment, "app.smtp.dev-auto-verify-otp", false);
        boolean production = isProductionProfile(environment);
        boolean explicitDevelopment = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(p -> "dev".equalsIgnoreCase(p)
                        || "local".equalsIgnoreCase(p)
                        || "test".equalsIgnoreCase(p));
        boolean boundToLoopback = isLoopback(environment.getProperty("server.address", ""));
        boolean localDevelopmentDatabase = isLocalDevelopmentDatabase(environment);

        boolean automaticLocalVerification = !production
                && localDevelopmentDatabase && boundToLoopback;

        if (enabled) {
            LOG.info("[AUTH CONFIG] perfiles={}, smtp.enabled=true, otp.verificacionInternaDev=false; "
                    + "modo=OTP_POR_CORREO (requiere reinicio si cambio el properties)",
                    Arrays.toString(environment.getActiveProfiles()));
            return new SmtpMode(true, false);
        }

        if (requested && (production || !boundToLoopback
                || (!explicitDevelopment && !automaticLocalVerification))) {
            throw new IllegalStateException(
                    "La verificacion interna de OTP exige un entorno local de desarrollo "
                            + "con server.address=127.0.0.1; no se admite en despliegues.");
        }

        boolean internal = automaticLocalVerification || requested;
        LOG.info("[AUTH CONFIG] perfiles={}, smtp.enabled=false, otp.verificacionInternaDev={}; "
                + "modo={} (requiere reinicio si cambio el properties)",
                Arrays.toString(environment.getActiveProfiles()), internal,
                internal ? "OTP_INTERNO_SOLO_DEV" : "MFA_SIN_CANAL");
        if (!internal) {
            LOG.warn("[AUTH CONFIG] SMTP deshabilitado sin MFA disponible. "
                    + "La verificacion interna solo funciona con DESCO_DB_dev en SQL Server local "
                    + "y server.address=127.0.0.1; no se omitira MFA en servidores publicos.");
        }
        return new SmtpMode(enabled, internal);
    }

    public static boolean isProductionProfile(Environment environment) {
        return Arrays.stream(environment.getActiveProfiles()).anyMatch(p ->
                "prod".equalsIgnoreCase(p) || "production".equalsIgnoreCase(p)
                        || "staging".equalsIgnoreCase(p) || "preprod".equalsIgnoreCase(p));
    }

    public static boolean isLocalDevelopmentDatabase(Environment environment) {
        String jdbc = environment.getProperty("spring.datasource.url", "").trim();
        if (!LOCAL_SQL_SERVER.matcher(jdbc).find()) return false;
        return Arrays.stream(jdbc.split(";"))
                .map(String::trim)
                .map(value -> value.toLowerCase(Locale.ROOT))
                .anyMatch("databasename=desco_db_dev"::equals);
    }

    private static boolean isLoopback(String configuredAddress) {
        String host = configuredAddress == null ? ""
                : configuredAddress.trim().toLowerCase(Locale.ROOT);
        return "127.0.0.1".equals(host) || "localhost".equals(host) || "::1".equals(host);
    }

    private static boolean readBoolean(Environment environment, String key, boolean fallback) {
        String value = environment.getProperty(key);
        if (value == null || value.isBlank()) return fallback;
        if ("true".equalsIgnoreCase(value.trim())) return true;
        if ("false".equalsIgnoreCase(value.trim())) return false;
        throw new IllegalStateException("Valor invalido en " + key + ": use true o false.");
    }
}
