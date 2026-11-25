package com.franco.desco.infrastructure.bootstrap;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

import static org.assertj.core.api.Assertions.assertThat;

class DemoPosAccountsBootstrapActivationTest {
    @Test
    void cuentasDemoSoloSeHabilitanDeFormaExplicita() {
        var condition = DemoPosAccountsBootstrap.class.getAnnotation(ConditionalOnProperty.class);
        assertThat(condition).isNotNull();
        assertThat(condition.prefix()).isEqualTo("desco.demo.pos");
        assertThat(condition.name()).containsExactly("enabled");
        assertThat(condition.havingValue()).isEqualTo("true");
        assertThat(condition.matchIfMissing()).isFalse();
    }
}
