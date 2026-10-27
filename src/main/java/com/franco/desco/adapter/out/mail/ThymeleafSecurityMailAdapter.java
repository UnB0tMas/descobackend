package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.domain.auth.SecurityNotification;
import com.franco.desco.infrastructure.config.MailProperties;
import jakarta.mail.internet.MimeMessage;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Component
@Primary
public final class ThymeleafSecurityMailAdapter
        implements SecurityMailPort {

    private static final String TEMPLATE =
            "email/security/security-message";

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;
    private final MailProperties properties;

    public ThymeleafSecurityMailAdapter(
            JavaMailSender mailSender,
            TemplateEngine templateEngine,
            MailProperties properties
    ) {
        this.mailSender = mailSender;
        this.templateEngine = templateEngine;
        this.properties = properties;
    }

    @Override
    public void sendTwoFactor(
            String destination,
            String code
    ) {
        send(
                destination,
                null,
                "Código de seguridad",
                "Código de seguridad DESCO",
                "Use el siguiente código para continuar con su autenticación.",
                code,
                "Código de seguridad",
                "No comparta este código con otras personas.",
                "Si no inició esta acción, puede ignorar este mensaje."
        );
    }

    @Override
    public void sendEmailVerification(
            String destination,
            String username,
            String code
    ) {
        send(
                destination,
                username,
                "Validación de correo",
                "Valide su correo de seguridad",
                "Use el siguiente código para validar su correo de seguridad.",
                code,
                "Código de validación",
                "No comparta este código con otras personas.",
                "Si no solicitó esta validación, puede ignorar este mensaje."
        );
    }

    @Override
    public void sendPasswordRecovery(
            String destination,
            String username,
            String code
    ) {
        send(
                destination,
                username,
                "Recuperación de contraseña",
                "Recupere el acceso a su cuenta",
                "Use el siguiente código para continuar con la recuperación de su contraseña.",
                code,
                "Código de recuperación",
                "No comparta este código con otras personas.",
                "Si no solicitó la recuperación, ignore este mensaje."
        );
    }

    @Override
    public void sendEmailChangeCode(
            String destination,
            String code
    ) {
        send(
                destination,
                null,
                "Cambio de correo",
                "Confirme su nuevo correo de seguridad",
                "Use el siguiente código para confirmar el cambio de correo.",
                code,
                "Código de confirmación",
                "No comparta este código con otras personas.",
                "Si no solicitó este cambio, revise la seguridad de su cuenta."
        );
    }

    @Override
    public void sendSecurityNotification(
            SecurityNotification notification
    ) {
        if (notification == null) {
            throw new IllegalArgumentException(
                    "La notificación de seguridad es obligatoria."
            );
        }

        String type =
                notification.tipoNotificacion() == null
                        ? ""
                        : notification.tipoNotificacion()
                        .trim()
                        .toUpperCase(Locale.ROOT);

        switch (type) {
            case "NUEVO_DISPOSITIVO" ->
                    send(
                            notification.correoDestino(),
                            null,
                            "Seguridad",
                            "Nuevo dispositivo detectado",
                            "Se detectó actividad de su cuenta desde un dispositivo nuevo.",
                            null,
                            null,
                            "Si reconoce esta actividad, no necesita realizar ninguna acción.",
                            "Si no reconoce esta actividad, cambie su contraseña y cierre las demás sesiones."
                    );

            case "CAMBIO_PASSWORD" ->
                    send(
                            notification.correoDestino(),
                            null,
                            "Seguridad",
                            "Su contraseña fue actualizada",
                            "La contraseña de su cuenta DESCO fue modificada correctamente.",
                            null,
                            null,
                            "Mantenga sus credenciales en un lugar seguro.",
                            "Si no realizó este cambio, comuníquese con soporte."
                    );

            case "CAMBIO_CORREO" ->
                    send(
                            notification.correoDestino(),
                            null,
                            "Seguridad",
                            "Correo de seguridad actualizado",
                            "El correo de seguridad asociado a su cuenta fue actualizado.",
                            null,
                            null,
                            "Revise que la información de seguridad de su cuenta sea correcta.",
                            "Si no realizó este cambio, comuníquese con soporte."
                    );

            default ->
                    send(
                            notification.correoDestino(),
                            null,
                            "Seguridad",
                            "Aviso de seguridad DESCO",
                            "Se registró una actividad de seguridad relacionada con su cuenta.",
                            null,
                            null,
                            "Revise la actividad reciente de su cuenta.",
                            "Si no reconoce esta actividad, comuníquese con soporte."
                    );
        }
    }

    private void send(
            String destination,
            String recipientName,
            String category,
            String title,
            String intro,
            String code,
            String codeLabel,
            String warningText,
            String closingText
    ) {
        String to = required(
                destination,
                "No existe un correo de destino."
        );

        String from = required(
                properties.from(),
                "No existe un correo remitente configurado."
        );

        Context context =
                new Context(
                        Locale.forLanguageTag("es")
                );

        context.setVariable(
                "companyName",
                fallback(
                        properties.companyName(),
                        "DESCO"
                )
        );
        context.setVariable(
                "unitName",
                fallback(
                        properties.unitName(),
                        "UOT Sara Sara"
                )
        );
        context.setVariable(
                "supportEmail",
                fallback(
                        properties.supportEmail(),
                        from
                )
        );
        context.setVariable(
                "currentYear",
                java.time.Year.now().getValue()
        );
        context.setVariable(
                "preheader",
                title
        );
        context.setVariable(
                "category",
                category
        );
        context.setVariable(
                "title",
                title
        );
        context.setVariable(
                "recipientName",
                blankToNull(recipientName)
        );
        context.setVariable(
                "intro",
                intro
        );
        context.setVariable(
                "code",
                blankToNull(code)
        );
        context.setVariable(
                "codeLabel",
                blankToNull(codeLabel)
        );
        context.setVariable(
                "expiryMinutes",
                null
        );
        context.setVariable(
                "actionUrl",
                null
        );
        context.setVariable(
                "actionLabel",
                null
        );
        context.setVariable(
                "warningTitle",
                "Importante"
        );
        context.setVariable(
                "warningText",
                warningText
        );
        context.setVariable(
                "closingText",
                closingText
        );

        String html =
                templateEngine.process(
                        TEMPLATE,
                        context
                );

        try {
            MimeMessage message =
                    mailSender.createMimeMessage();

            MimeMessageHelper helper =
                    new MimeMessageHelper(
                            message,
                            false,
                            StandardCharsets.UTF_8.name()
                    );

            String fromName =
                    blankToNull(
                            properties.fromName()
                    );

            if (fromName == null) {
                helper.setFrom(from);
            } else {
                helper.setFrom(
                        from,
                        fromName
                );
            }

            String replyTo =
                    blankToNull(
                            properties.replyTo()
                    );

            if (replyTo != null) {
                helper.setReplyTo(replyTo);
            }

            helper.setTo(to);
            helper.setSubject(title);
            helper.setText(
                    html,
                    true
            );

            mailSender.send(message);

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo enviar el correo de seguridad.",
                    exception
            );
        }
    }

    private String required(
            String value,
            String message
    ) {
        String normalized =
                blankToNull(value);

        if (normalized == null) {
            throw new IllegalArgumentException(
                    message
            );
        }

        return normalized;
    }

    private String fallback(
            String value,
            String fallback
    ) {
        String normalized =
                blankToNull(value);

        return normalized == null
                ? fallback
                : normalized;
    }

    private String blankToNull(
            String value
    ) {
        if (value == null) {
            return null;
        }

        String normalized =
                value.trim();

        return normalized.isEmpty()
                ? null
                : normalized;
    }
}
