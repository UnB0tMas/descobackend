package com.franco.desco;

import com.franco.desco.infrastructure.config.SmtpMode;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.Map;

@EnableScheduling
@ConfigurationPropertiesScan
@SpringBootApplication
public class DescoApplication {

    public static void main(String[] args) {
        SpringApplication application = new SpringApplication(DescoApplication.class);
        application.addInitializers(context ->
                prepararEntornoLocal(context.getEnvironment()));
        application.run(args);
    }

    /**
     * Instalación local de DESCO (BD DESCO_DB_dev en localhost) sin correo:
     * el servidor debe escuchar exclusivamente en loopback. No altera
     * propiedades cuando SMTP está habilitado, el perfil es productivo o
     * la base de datos no es la base local de desarrollo conocida.
     *
     * No activa ningún perfil ni crea archivos de configuración adicionales.
     */
    public static void prepararEntornoLocal(ConfigurableEnvironment environment) {
        if (SmtpMode.isProductionProfile(environment)
                || !SmtpMode.isLocalDevelopmentDatabase(environment)
                || !"false".equalsIgnoreCase(
                        environment.getProperty("app.smtp.enabled", "false").trim())) {
            return;
        }
        String configuredAddress = environment.getProperty("server.address", "").trim();
        if (configuredAddress.isEmpty()) {
            environment.getPropertySources().addFirst(
                    new MapPropertySource("desco-local-dev-loopback",
                            Map.of("server.address", "127.0.0.1")));
        }
        // Si alguien configura explícitamente 0.0.0.0 u otra IP pública,
        // SmtpMode rechazará la autoverificación, sin abrir un bypass MFA.
    }
}
