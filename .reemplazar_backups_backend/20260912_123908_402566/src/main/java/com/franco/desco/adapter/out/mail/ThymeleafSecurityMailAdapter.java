package com.franco.desco.adapter.out.mail;

import com.franco.desco.application.auth.port.out.SecurityMailPort;
import com.franco.desco.domain.auth.SecurityNotification;
import org.springframework.stereotype.Component;

import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

@Component
public class ThymeleafSecurityMailAdapter implements SecurityMailPort {

    private static final ZoneId PERU_ZONE = ZoneId.of("America/Lima");
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter
            .ofPattern("dd/MM/yyyy 'a las' HH:mm")
            .withZone(PERU_ZONE);

    private final EmailTemplateService templateService;
    private final MailDeliveryService deliveryService;
    private final SecurityEmailLinkService linkService;

    public ThymeleafSecurityMailAdapter(
            EmailTemplateService templateService,
            MailDeliveryService deliveryService,
            SecurityEmailLinkService linkService
    ) {
        this.templateService = templateService;
        this.deliveryService = deliveryService;
        this.linkService = linkService;
    }

    @Override
    public void sendEmailVerification(String destination, String username, String code) {
        deliver(destination, new SecurityEmailModel(
                "Verifica tu correo de seguridad | DESCO",
                "Confirma tu correo para completar la seguridad de tu cuenta DESCO.",
                "SEGURIDAD DE CUENTA",
                "Verifica tu correo de seguridad",
                username,
                "Para continuar utilizando tu cuenta, necesitamos confirmar que este correo de seguridad te pertenece.",
                "Ingresa el código mostrado a continuación en la pantalla de verificación. Es personal, de un solo uso y de vigencia limitada.",
                "Código de verificación",
                code,
                "Abrir verificación",
                linkService.emailVerification(username),
                "Protege este código",
                "DESCO nunca te solicitará este código por teléfono, chat, mensajería instantánea ni redes sociales.",
                "Si no solicitaste esta verificación, puedes ignorar este correo."
        ));
    }

    @Override
    public void sendTwoFactor(String destination, String code) {
        deliver(destination, new SecurityEmailModel(
                "Código de seguridad para iniciar sesión | DESCO",
                "Se solicitó una verificación adicional para iniciar sesión en tu cuenta DESCO.",
                "VERIFICACIÓN EN DOS PASOS",
                "Confirma tu inicio de sesión",
                null,
                "Se está intentando iniciar sesión en tu cuenta y necesitamos una verificación adicional.",
                "Ingresa este código únicamente en la pantalla oficial de DESCO. El código es de un solo uso y tiene una vigencia limitada.",
                "Código de seguridad",
                code,
                "Continuar con el inicio de sesión",
                linkService.twoFactor(),
                "¿No fuiste tú?",
                "No compartas este código. Si no reconoces el intento, no continúes con el acceso.",
                "Este mensaje fue generado automáticamente por los controles de seguridad de DESCO."
        ));
    }

    @Override
    public void sendPasswordRecovery(String destination, String username, String code) {
        deliver(destination, new SecurityEmailModel(
                "Recuperación de contraseña | DESCO",
                "Recibimos una solicitud para restablecer la contraseña de tu cuenta DESCO.",
                "RECUPERACIÓN DE CUENTA",
                "Restablece tu contraseña",
                username,
                "Recibimos una solicitud para recuperar el acceso a tu cuenta.",
                "Utiliza el código en la pantalla de recuperación. El botón abre el portal oficial, pero el código se confirma dentro del proceso y nunca viaja en la URL.",
                "Código de recuperación",
                code,
                "Restablecer contraseña",
                linkService.passwordRecovery(username),
                "No compartas este código",
                "El personal de DESCO no necesita conocer tu contraseña ni tu código de recuperación para ayudarte.",
                "Si no realizaste esta solicitud, no necesitas responder este correo."
        ));
    }

    @Override
    public void sendEmailChangeCode(String destination, String code) {
        deliver(destination, new SecurityEmailModel(
                "Confirma tu nuevo correo de seguridad | DESCO",
                "Confirma el nuevo correo que se asociará a tu cuenta DESCO.",
                "CAMBIO DE CORREO",
                "Confirma tu nuevo correo de seguridad",
                null,
                "Recibimos una solicitud para cambiar el correo de seguridad asociado a tu cuenta.",
                "Ingresa este código en la sección Mi cuenta > Seguridad. El código es de un solo uso y nunca se incluye dentro del enlace.",
                "Código de confirmación",
                code,
                "Abrir seguridad de mi cuenta",
                linkService.accountSecurity(),
                "¿No solicitaste este cambio?",
                "No compartas el código y revisa inmediatamente tus sesiones si no reconoces esta solicitud.",
                "El correo solo se actualizará cuando el código sea confirmado correctamente."
        ));
    }

    @Override
    public void sendSecurityNotification(SecurityNotification notification) {
        SecurityEmailModel model = switch (notification.tipoNotificacion()) {
            case "NUEVO_DISPOSITIVO" -> newDevice(notification);
            case "CAMBIO_PASSWORD" -> passwordChanged(notification);
            case "CAMBIO_CORREO" -> emailChanged(notification);
            default -> generic(notification);
        };
        deliver(notification.correoDestino(), model);
    }

    private SecurityEmailModel newDevice(SecurityNotification notification) {
        return new SecurityEmailModel(
                "Nuevo dispositivo detectado | DESCO",
                "Se detectó un nuevo dispositivo asociado a tu cuenta DESCO.",
                "ALERTA DE SEGURIDAD",
                "Detectamos un nuevo dispositivo",
                null,
                "Se registró un acceso desde un dispositivo que no había sido reconocido previamente.",
                activity(notification),
                null,
                null,
                "Revisar seguridad de mi cuenta",
                linkService.accountSecurity(),
                "Si no reconoces esta actividad",
                "Cambia tu contraseña y cierra las demás sesiones desde la sección Seguridad.",
                "Por seguridad, no reenvíes este mensaje a terceros."
        );
    }

    private SecurityEmailModel passwordChanged(SecurityNotification notification) {
        return new SecurityEmailModel(
                "Tu contraseña fue actualizada | DESCO",
                "La contraseña de tu cuenta DESCO fue actualizada.",
                "CONFIRMACIÓN DE SEGURIDAD",
                "Tu contraseña fue actualizada",
                null,
                "La contraseña asociada a tu cuenta se cambió correctamente.",
                activity(notification),
                null,
                null,
                "Revisar mis sesiones",
                linkService.sessions(),
                "¿No realizaste este cambio?",
                "Contacta al responsable del sistema y revisa inmediatamente tus sesiones.",
                "DESCO nunca enviará tu contraseña por correo electrónico."
        );
    }

    private SecurityEmailModel emailChanged(SecurityNotification notification) {
        return new SecurityEmailModel(
                "Tu correo de seguridad fue actualizado | DESCO",
                "El correo de seguridad asociado a tu cuenta DESCO fue actualizado.",
                "CONFIRMACIÓN DE SEGURIDAD",
                "Tu correo de seguridad fue actualizado",
                null,
                "Se registró un cambio en el correo utilizado para verificaciones y recuperación.",
                activity(notification),
                null,
                null,
                "Revisar seguridad de mi cuenta",
                linkService.accountSecurity(),
                "¿No solicitaste este cambio?",
                "Comunícate con el responsable del sistema para revisar la cuenta.",
                "Mantén actualizado únicamente un correo al que tengas acceso seguro."
        );
    }

    private SecurityEmailModel generic(SecurityNotification notification) {
        return new SecurityEmailModel(
                "Notificación de seguridad | DESCO",
                "Se registró una actividad de seguridad relevante en tu cuenta DESCO.",
                "SEGURIDAD DE CUENTA",
                "Actividad de seguridad registrada",
                null,
                "DESCO registró una actividad de seguridad relacionada con tu cuenta.",
                activity(notification),
                null,
                null,
                "Revisar seguridad de mi cuenta",
                linkService.accountSecurity(),
                "Mantén tu cuenta protegida",
                "Si no reconoces esta actividad, revisa tus sesiones y cambia tu contraseña.",
                "Este es un mensaje automático de seguridad."
        );
    }

    private String activity(SecurityNotification notification) {
        return notification.fechaCreacionUtc() == null
                ? "Revisa la actividad reciente de tu cuenta."
                : "Actividad registrada el " + DATE_TIME.format(notification.fechaCreacionUtc()) + ".";
    }

    private void deliver(String destination, SecurityEmailModel model) {
        deliveryService.send(destination, templateService.render(model));
    }
}
