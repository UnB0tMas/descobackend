package com.franco.desco.adapter.out.mail;

import com.franco.desco.infrastructure.config.MailProperties;
import jakarta.mail.internet.MimeMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Component
public class MailDeliveryService {

    private final JavaMailSender mailSender;
    private final MailProperties properties;

    public MailDeliveryService(
            JavaMailSender mailSender,
            MailProperties properties
    ) {
        this.mailSender = mailSender;
        this.properties = properties;
    }

    public String send(
            String destination,
            EmailTemplateService.RenderedEmail email
    ) {
        if (destination == null
                || destination.isBlank()) {
            throw new IllegalArgumentException(
                    "El correo de destino es obligatorio."
            );
        }

        try {
            MimeMessage message =
                    mailSender.createMimeMessage();

            MimeMessageHelper helper =
                    new MimeMessageHelper(
                            message,
                            MimeMessageHelper
                                    .MULTIPART_MODE_MIXED_RELATED,
                            StandardCharsets.UTF_8
                                    .name()
                    );

            helper.setFrom(
                    properties.from(),
                    properties.fromName()
            );

            helper.setTo(
                    destination.trim()
            );

            if (properties.replyTo() != null
                    && !properties
                    .replyTo()
                    .isBlank()) {
                helper.setReplyTo(
                        properties.replyTo()
                );
            }

            helper.setSubject(
                    email.subject()
            );

            helper.setText(
                    email.plainText(),
                    email.html()
            );

            message.saveChanges();

            String messageId =
                    message.getMessageID();

            mailSender.send(message);

            return messageId == null
                    ? UUID.randomUUID()
                    .toString()
                    : messageId;

        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo completar el envío del correo.",
                    exception
            );
        }
    }
}
