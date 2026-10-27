package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.infrastructure.config.MailProperties;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
public final class SmtpSecurityMailAdapter
        implements SecurityMailPort {

    private final JavaMailSender mailSender;
    private final MailProperties properties;

    public SmtpSecurityMailAdapter(
            JavaMailSender mailSender,
            MailProperties properties
    ) {
        this.mailSender = mailSender;
        this.properties = properties;
    }

    @Override
    public void sendTwoFactor(
            String destination,
            String code
    ) {
        send(
                destination,
                "Código de seguridad DESCO",
                """
                Su código de seguridad es: %s

                Si no inició esta acción, ignore este mensaje.
                """
                        .formatted(code)
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
                "Validación de correo DESCO",
                """
                Hola %s:

                Su código para validar el correo es: %s
                """
                        .formatted(
                                safe(username),
                                code
                        )
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
                "Recuperación de contraseña DESCO",
                """
                Hola %s:

                Su código de recuperación es: %s

                Si no solicitó el cambio, ignore este mensaje.
                """
                        .formatted(
                                safe(username),
                                code
                        )
        );
    }

    @Override
    public void sendEmailChangeCode(
            String destination,
            String code
    ) {
        send(
                destination,
                "Cambio de correo de seguridad DESCO",
                """
                Su código para confirmar el nuevo correo es: %s
                """
                        .formatted(code)
        );
    }

    @Override
    public void sendNewDevice(
            String destination,
            String browser,
            String operatingSystem,
            String ip
    ) {
        send(
                destination,
                "Nuevo dispositivo en DESCO",
                """
                Detectamos un inicio de sesión desde un dispositivo nuevo.

                Navegador: %s
                Sistema: %s
                IP: %s

                Si reconoce este acceso, no necesita realizar ninguna acción.
                Si no lo reconoce, cambie su contraseña y cierre las demás sesiones.
                """
                        .formatted(
                                safeDetail(browser),
                                safeDetail(operatingSystem),
                                safeDetail(ip)
                        )
        );
    }

    private void send(
            String destination,
            String subject,
            String body
    ) {
        if (destination == null
                || destination.isBlank()) {
            throw new IllegalArgumentException(
                    "No existe un correo de destino."
            );
        }

        SimpleMailMessage message =
                new SimpleMailMessage();

        message.setFrom(
                properties.from()
        );

        message.setReplyTo(
                properties.replyTo()
        );

        message.setTo(
                destination.trim()
        );

        message.setSubject(subject);

        message.setText(
                properties.companyName()
                        + " - "
                        + properties.unitName()
                        + "\n\n"
                        + body.trim()
        );

        mailSender.send(message);
    }

    private String safe(String value) {
        return value == null
                ? "usuario"
                : value.trim();
    }

    private String safeDetail(String value) {
        return value == null || value.isBlank()
                ? "No disponible"
                : value.trim();
    }
}
