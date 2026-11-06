package com.franco.desco.infrastructure.config;

import com.franco.desco.DescoApplication;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SmtpModeTest {
    private static final String LOCAL_DB =
            "jdbc:sqlserver://localhost:1433;databaseName=DESCO_DB_dev;encrypt=true";

    private MockEnvironment local(String smtp) {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", smtp)
                .withProperty("app.smtp.dev-auto-verify-otp", "true")
                .withProperty("server.address", "127.0.0.1");
        env.setActiveProfiles("dev");
        return env;
    }

    @Test void noSeDesactivaMfaSinConfiguracionLocal() {
        SmtpMode mode = SmtpMode.from(new MockEnvironment());
        assertThat(mode.enabled()).isFalse();
        assertThat(mode.devAutoVerifyOtp()).isFalse();
    }

    @Test void desdeIntellijPerfilDefaultYBaseDevLocalNoSeRequiereCorreo() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("app.smtp.dev-auto-verify-otp", "false")
                .withProperty("spring.datasource.url", LOCAL_DB);
        DescoApplication.prepararEntornoLocal(env);
        assertThat(env.getProperty("server.address")).isEqualTo("127.0.0.1");
        assertThat(SmtpMode.from(env).devAutoVerifyOtp()).isTrue();
    }

    @Test void smtpActivadoMantieneDobleFactor() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "true")
                .withProperty("spring.datasource.url", LOCAL_DB);
        DescoApplication.prepararEntornoLocal(env);
        assertThat(env.getProperty("server.address")).isNull();
        assertThat(SmtpMode.from(env).devAutoVerifyOtp()).isFalse();
    }

    @Test void bdDistintaNoPermiteMfaInterno() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("spring.datasource.url",
                        "jdbc:sqlserver://localhost:1433;databaseName=DESCO_DB_prod")
                .withProperty("server.address", "127.0.0.1");
        assertThat(SmtpMode.from(env).devAutoVerifyOtp()).isFalse();
    }

    @Test void servidorExpuestoEnRedNoPermiteMfaInterno() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("spring.datasource.url", LOCAL_DB)
                .withProperty("server.address", "0.0.0.0");
        DescoApplication.prepararEntornoLocal(env);
        assertThat(env.getProperty("server.address")).isEqualTo("0.0.0.0");
        assertThat(SmtpMode.from(env).devAutoVerifyOtp()).isFalse();
    }

    @Test void perfilProduccionNuncaHabilitaVerificacionInterna() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("spring.datasource.url", LOCAL_DB)
                .withProperty("server.address", "127.0.0.1");
        env.setActiveProfiles("prod");
        DescoApplication.prepararEntornoLocal(env);
        assertThat(SmtpMode.from(env).devAutoVerifyOtp()).isFalse();
    }

    @Test void perfilDevLocalHabilitaVerificacionInterna() {
        assertThat(SmtpMode.from(local("false")).devAutoVerifyOtp()).isTrue();
    }

    @Test void perfilDevConSmtpTrueSoloUsaCorreo() {
        SmtpMode mode = SmtpMode.from(local("true"));
        assertThat(mode.enabled()).isTrue();
        assertThat(mode.devAutoVerifyOtp()).isFalse();
    }

    @Test void peticionExplicitaSinEntornoSeguroSeRechaza() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("app.smtp.dev-auto-verify-otp", "true")
                .withProperty("server.address", "127.0.0.1");
        assertThatThrownBy(() -> SmtpMode.from(env))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test void configuracionNoBooleanaSeRechaza() {
        assertThatThrownBy(() -> SmtpMode.from(new MockEnvironment()
                .withProperty("app.smtp.enabled", "apagado")))
                .isInstanceOf(IllegalStateException.class);
    }
    @Test void alternarDeFalseATrueDesactivaSiempreOtpInterno() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "false")
                .withProperty("spring.datasource.url", LOCAL_DB)
                .withProperty("server.address", "127.0.0.1");
        SmtpMode disabled = SmtpMode.from(env);
        assertThat(disabled.enabled()).isFalse();
        assertThat(disabled.devAutoVerifyOtp()).isTrue();

        env.setProperty("app.smtp.enabled", "true");
        SmtpMode enabled = SmtpMode.from(env);
        assertThat(enabled.enabled()).isTrue();
        assertThat(enabled.devAutoVerifyOtp()).isFalse();
    }

    @Test void smtpTrueTienePrioridadSobreOverrideDevLegacy() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("app.smtp.enabled", "true")
                .withProperty("app.smtp.dev-auto-verify-otp", "true")
                .withProperty("spring.datasource.url", LOCAL_DB)
                .withProperty("server.address", "127.0.0.1");
        env.setActiveProfiles("dev");
        SmtpMode mode = SmtpMode.from(env);
        assertThat(mode.enabled()).isTrue();
        assertThat(mode.devAutoVerifyOtp()).isFalse();
    }

    @Test void applicationPropertiesContieneUnSoloInterruptorSmtp() throws Exception {
        java.net.URL url = getClass().getResource("/application.properties");
        assertThat(url).isNotNull();
        try (java.io.BufferedReader reader = new java.io.BufferedReader(
                new java.io.InputStreamReader(url.openStream(), java.nio.charset.StandardCharsets.UTF_8))) {
            long count = reader.lines().filter(line ->
                    line.strip().matches("app\\.smtp\\.enabled\\s*=.*")).count();
            assertThat(count).isEqualTo(1);
        }
    }

}
