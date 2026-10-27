package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.domain.auth.SecurityNotification;
import com.franco.desco.infrastructure.config.MailProperties;
import jakarta.mail.internet.MimeMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import tools.jackson.databind.json.JsonMapper;

import java.nio.charset.StandardCharsets;
import java.time.Year;
import java.util.Locale;
import java.util.Map;

@Component
public final class SmtpSecurityMailAdapter
        implements SecurityMailPort {

    private static final String SECURITY_TEMPLATE =
            "email/security/security-message";

    private final JavaMailSender mailSender;
    private final MailProperties properties;
    private final JsonMapper jsonMapper;
    private final TemplateEngine templateEngine;

    public SmtpSecurityMailAdapter(
            JavaMailSender mailSender,
            MailProperties properties,
            JsonMapper jsonMapper,
            TemplateEngine templateEngine
    ) {
        this.mailSender = mailSender;
        this.properties = properties;
        this.jsonMapper = jsonMapper;
        this.templateEngine = templateEngine;
    }

    @Override
    public void sendTwoFactor(
            String destination,
            String code
    ) {
        sendTemplate(
                destination,
                "Código de seguridad DESCO",
                null,
                "Código de seguridad",
                "Usa el siguiente código para continuar con el inicio de sesión.",
                code,
                "Código de seguridad",
                "No compartas este código",
                "DESCO nunca te solicitará este código por teléfono, mensajería o correo.",
                "Si no intentaste iniciar sesión, puedes ignorar este mensaje de forma segura."
        );
    }

    @Override
    public void sendEmailVerification(
            String destination,
            String username,
            String code
    ) {
        sendTemplate(
                destination,
                "Validación de correo DESCO",
                safe(username),
                "Valida tu correo de seguridad",
                "Usa el siguiente código para validar tu correo de seguridad.",
                code,
                "Código de verificación",
                "Protege tu cuenta",
                "No compartas este código con otras personas.",
                "Si no solicitaste esta validación, puedes ignorar este mensaje."
        );
    }

    @Override
    public void sendPasswordRecovery(
            String destination,
            String username,
            String code
    ) {
        sendTemplate(
                destination,
                "Recuperación de contraseña DESCO",
                safe(username),
                "Recupera tu contraseña",
                "Usa el siguiente código para continuar con la recuperación de tu contraseña.",
                code,
                "Código de recuperación",
                "Solicitud de seguridad",
                "No compartas este código. Si no solicitaste el cambio, ignora este mensaje.",
                "Este código solo puede utilizarse para continuar con la recuperación solicitada."
        );
    }

    @Override
    public void sendEmailChangeCode(
            String destination,
            String code
    ) {
        sendTemplate(
                destination,
                "Cambio de correo de seguridad DESCO",
                null,
                "Confirma tu nuevo correo",
                "Usa el siguiente código para confirmar el nuevo correo de seguridad.",
                code,
                "Código de confirmación",
                "Confirma solo si reconoces el cambio",
                "Si no solicitaste modificar tu correo de seguridad, no uses este código.",
                "El cambio solo se completará después de validar correctamente el código."
        );
    }

    @Override
    public void sendNewDevice(
            String destination,
            String browser,
            String operatingSystem,
            String ip
    ) {
        sendTemplate(
                destination,
                "Nuevo dispositivo en DESCO",
                null,
                "Nuevo dispositivo detectado",
                "Detectamos un inicio de sesión desde un dispositivo nuevo.",
                null,
                null,
                "Detalles del acceso",
                newDeviceDetails(
                        browser,
                        operatingSystem,
                        ip
                ),
                "Si reconoces este acceso, no necesitas realizar ninguna acción. Si no lo reconoces, cambia tu contraseña y cierra las demás sesiones."
        );
    }

    @Override
    public void sendSecurityNotification(
            SecurityNotification notification
    ) {
        if (notification == null
                || notification.correoDestino() == null
                || notification.correoDestino().isBlank()) {
            throw new IllegalArgumentException(
                    "La notificación de seguridad no tiene destinatario."
            );
        }

        String type = notification.tipoNotificacion() == null
                ? ""
                : notification.tipoNotificacion()
                        .trim()
                        .toUpperCase(Locale.ROOT);

        switch (type) {
            case "NUEVO_DISPOSITIVO" -> {
                Map<String, Object> metadata = metadata(
                        notification.metadata()
                );
                sendNewDevice(
                        notification.correoDestino(),
                        text(metadata.get("navegador")),
                        text(metadata.get("sistemaOperativo")),
                        text(metadata.get("ip"))
                );
            }
            case "CAMBIO_PASSWORD" -> sendTemplate(
                    notification.correoDestino(),
                    "Contraseña actualizada en DESCO",
                    null,
                    "Contraseña actualizada",
                    "La contraseña de tu cuenta fue actualizada correctamente.",
                    null,
                    null,
                    "¿No reconoces este cambio?",
                    "Comunícate con el administrador y cierra tus sesiones activas.",
                    "Este mensaje es una notificación automática de seguridad."
            );
            case "CAMBIO_CORREO" -> sendTemplate(
                    notification.correoDestino(),
                    "Correo de seguridad actualizado en DESCO",
                    null,
                    "Correo de seguridad actualizado",
                    "El correo de seguridad de tu cuenta fue actualizado correctamente.",
                    null,
                    null,
                    "¿No reconoces este cambio?",
                    "Comunícate con el administrador para revisar la seguridad de tu cuenta.",
                    "Este mensaje es una notificación automática de seguridad."
            );
            default -> throw new IllegalArgumentException(
                    "El tipo de notificación de seguridad no está soportado."
            );
        }
    }

    private void sendTemplate(
            String destination,
            String subject,
            String recipientName,
            String title,
            String intro,
            String code,
            String codeLabel,
            String warningTitle,
            String warningText,
            String closingText
    ) {
        if (destination == null
                || destination.isBlank()) {
            throw new IllegalArgumentException(
                    "No existe un correo de destino."
            );
        }

        Context context = new Context(
                Locale.forLanguageTag("es-PE")
        );

        context.setVariable("companyName", safeBrand(properties.companyName(), "DESCO"));
        context.setVariable("unitName", safeBrand(properties.unitName(), "UOT Sara Sara"));
        context.setVariable("supportEmail", blankToNull(properties.supportEmail()));
        context.setVariable("currentYear", Year.now().getValue());
        context.setVariable("preheader", subject);
        context.setVariable("category", "SEGURIDAD");
        context.setVariable("title", title);
        context.setVariable("recipientName", blankToNull(recipientName));
        context.setVariable("intro", intro);
        context.setVariable("code", blankToNull(code));
        context.setVariable("codeLabel", blankToNull(codeLabel));
        context.setVariable("expiryMinutes", null);
        context.setVariable("actionUrl", null);
        context.setVariable("actionLabel", null);
        context.setVariable("warningTitle", blankToNull(warningTitle));
        context.setVariable("warningText", blankToNull(warningText));
        context.setVariable("closingText", closingText);

        String html = templateEngine.process(
                SECURITY_TEMPLATE,
                context
        );

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message,
                    false,
                    StandardCharsets.UTF_8.name()
            );

            String from = properties.from();
            String fromName = properties.fromName();

            if (fromName == null || fromName.isBlank()) {
                helper.setFrom(from);
            } else {
                helper.setFrom(from, fromName.trim());
            }

            if (properties.replyTo() != null
                    && !properties.replyTo().isBlank()) {
                helper.setReplyTo(
                        properties.replyTo().trim()
                );
            }

            helper.setTo(destination.trim());
            helper.setSubject(subject);
            helper.setText(html, true);

            mailSender.send(message);
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo enviar el correo de seguridad.",
                    exception
            );
        }
    }

    private Map<String, Object> metadata(
            String value
    ) {
        if (value == null || value.isBlank()) {
            return Map.of();
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> parsed =
                    jsonMapper.readValue(
                            value,
                            Map.class
                    );
            return parsed == null
                    ? Map.of()
                    : parsed;
        } catch (Exception exception) {
            return Map.of();
        }
    }

    private String newDeviceDetails(
            String browser,
            String operatingSystem,
            String ip
    ) {
        return "Navegador: %s · Sistema: %s · IP: %s"
                .formatted(
                        safeDetail(browser),
                        safeDetail(operatingSystem),
                        safeDetail(ip)
                );
    }

    private String text(Object value) {
        return value == null
                ? null
                : value.toString();
    }

    private String safe(String value) {
        return value == null || value.isBlank()
                ? "usuario"
                : value.trim();
    }

    private String safeDetail(String value) {
        return value == null || value.isBlank()
                ? "No disponible"
                : value.trim();
    }

    private String safeBrand(
            String value,
            String fallback
    ) {
        return value == null || value.isBlank()
                ? fallback
                : value.trim();
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank()
                ? null
                : value.trim();
    }
}
