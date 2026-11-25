package com.franco.desco;

import com.franco.desco.infrastructure.config.SmtpMode;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.util.HashMap;
import java.util.Map;

@EnableScheduling
@ConfigurationPropertiesScan
@SpringBootApplication
public class DescoApplication {

    public static void main(String[] args) {
        SpringApplication application = new SpringApplication(DescoApplication.class);
        application.addInitializers(context -> {
            prepararConexionBaseDatos(context.getEnvironment());
            prepararEntornoLocal(context.getEnvironment());
        });
        application.run(args);
    }

    public static void prepararConexionBaseDatos(ConfigurableEnvironment environment) {
        String ambiente = environment.getProperty("app.database.environment", "dev").trim();
        if ("dev".equalsIgnoreCase(ambiente)) {
            return;
        }
        if (!"prod".equalsIgnoreCase(ambiente)) {
            throw new IllegalStateException("app.database.environment debe ser dev o prod.");
        }

        String url = propiedadConexionRequerida(environment, "app.database.prod.url");
        String username = propiedadConexionRequerida(environment, "app.database.prod.username");
        String password = propiedadConexionRequerida(environment, "app.database.prod.password");

        Map<String, Object> conexion = new HashMap<>();
        conexion.put("spring.datasource.url", url);
        conexion.put("spring.datasource.username", username);
        conexion.put("spring.datasource.password", password);

        // Evita que propiedades JDBC especificas de Hikari conserven la conexion DEV.
        if (environment.containsProperty("spring.datasource.hikari.jdbc-url")) {
            conexion.put("spring.datasource.hikari.jdbc-url", url);
        }
        if (environment.containsProperty("spring.datasource.hikari.username")) {
            conexion.put("spring.datasource.hikari.username", username);
        }
        if (environment.containsProperty("spring.datasource.hikari.password")) {
            conexion.put("spring.datasource.hikari.password", password);
        }

        // Si Flyway tiene una conexion propia, debe apuntar al mismo ambiente.
        if (environment.containsProperty("spring.flyway.url")
                || environment.containsProperty("spring.flyway.user")
                || environment.containsProperty("spring.flyway.password")) {
            conexion.put("spring.flyway.url", url);
            conexion.put("spring.flyway.user", username);
            conexion.put("spring.flyway.password", password);
        }

        environment.getPropertySources().addFirst(
                new MapPropertySource("desco-database-prod", conexion));
    }

    private static String propiedadConexionRequerida(ConfigurableEnvironment environment, String key) {
        String value = environment.getProperty(key);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Falta configurar " + key + " para PROD.");
        }
        return value;
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
