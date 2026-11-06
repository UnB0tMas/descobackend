package com.franco.desco.infrastructure.mail;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.franco.desco.infrastructure.config.SmtpMode;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Component;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public final class MailStartupDiagnostics
        implements ApplicationRunner {

    private static final Logger log =
            LoggerFactory.getLogger(MailStartupDiagnostics.class);

    private final JavaMailSender mailSender;
    private final Environment environment;
    private final SmtpMode smtpMode;

    public MailStartupDiagnostics(
            JavaMailSender mailSender,
            Environment environment,
            SmtpMode smtpMode
    ) {
        this.mailSender = mailSender;
        this.environment = environment;
        this.smtpMode = smtpMode;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!smtpMode.enabled()) {
            log.info("[MAIL] SMTP deshabilitado por configuración; test de conexión omitido.");
            return;
        }
        String configuredHost =
                value(environment.getProperty("spring.mail.host"));

        if (!(mailSender instanceof JavaMailSenderImpl implementation)) {
            log.warn(
                    "[MAIL] SMTP connection test skipped: sender={}",
                    mailSender.getClass().getSimpleName()
            );
            return;
        }

        normalizeGmailAppPassword(
                implementation,
                configuredHost
        );

        String host = firstNonBlank(
                implementation.getHost(),
                configuredHost
        );

        int port = implementation.getPort();

        try {
            implementation.testConnection();

            log.info(
                    "[MAIL] SMTP ready host={} port={}",
                    host,
                    port
            );
        } catch (Exception exception) {
            log.error(
                    "[MAIL] SMTP unavailable host={} port={} error={}",
                    host,
                    port,
                    safeMessage(exception.getMessage())
            );

            log.debug(
                    "[MAIL] SMTP failure detail",
                    exception
            );
        }
    }

    private void normalizeGmailAppPassword(
            JavaMailSenderImpl implementation,
            String configuredHost
    ) {
        String host = firstNonBlank(
                implementation.getHost(),
                configuredHost
        );

        if (!"smtp.gmail.com".equalsIgnoreCase(host)) {
            return;
        }

        String password = implementation.getPassword();

        if (password == null || password.isBlank()) {
            log.error(
                    "[MAIL] SMTP configuration error: Gmail application password is missing."
            );
            return;
        }

        String compact = password.replaceAll("\\s+", "");

        if (compact.equals(password)) {
            return;
        }

        if (compact.length() != 16) {
            log.warn(
                    "[MAIL] SMTP configuration warning: Gmail application password has an unexpected length after whitespace normalization."
            );
            return;
        }

        implementation.setPassword(compact);
    }

    private String firstNonBlank(
            String first,
            String second
    ) {
        if (first != null && !first.isBlank()) {
            return first.trim();
        }

        return value(second);
    }

    private String value(String input) {
        return input == null || input.isBlank()
                ? "(not configured)"
                : input.trim();
    }

    private String safeMessage(String input) {
        if (input == null || input.isBlank()) {
            return "(no detail)";
        }

        String text =
                input.replace('\r', ' ')
                        .replace('\n', ' ')
                        .trim();

        return text.length() <= 300
                ? text
                : text.substring(0, 300);
    }
}
