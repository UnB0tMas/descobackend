package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.domain.auth.SecurityNotification;
import com.franco.desco.infrastructure.config.MailProperties;
import org.springframework.context.annotation.Primary;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.util.Locale;
import java.util.Map;

@Primary
@Component
public final class SmtpSecurityMailAdapter
        implements SecurityMailPort {

    private final JavaMailSender mailSender;
    private final MailProperties properties;
    private final JsonMapper jsonMapper;

    public SmtpSecurityMailAdapter(
            JavaMailSender mailSender,
            MailProperties properties,
            JsonMapper jsonMapper
    ) {
        this.mailSender = mailSender;
        this.properties = properties;
        this.jsonMapper = jsonMapper;
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
                newDeviceBody(
                        browser,
                        operatingSystem,
                        ip
                )
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
            case "CAMBIO_PASSWORD" -> send(
                    notification.correoDestino(),
                    "Contraseña actualizada en DESCO",
                    """
                    La contraseña de su cuenta fue actualizada.

                    Si no reconoce este cambio, comuníquese con el administrador y cierre sus sesiones activas.
                    """
            );
            case "CAMBIO_CORREO" -> send(
                    notification.correoDestino(),
                    "Correo de seguridad actualizado en DESCO",
                    """
                    El correo de seguridad de su cuenta fue actualizado.

                    Si no reconoce este cambio, comuníquese con el administrador.
                    """
            );
            default -> throw new IllegalArgumentException(
                    "El tipo de notificación de seguridad no está soportado."
            );
        }
    }

    private String newDeviceBody(
            String browser,
            String operatingSystem,
            String ip
    ) {
        return """
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
                );
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

    private String text(Object value) {
        return value == null
                ? null
                : value.toString();
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
        return value == null || value.isBlank()
                ? "usuario"
                : value.trim();
    }

    private String safeDetail(String value) {
        return value == null || value.isBlank()
                ? "No disponible"
                : value.trim();
    }
}
