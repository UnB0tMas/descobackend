package com.franco.desco.infrastructure.bootstrap;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

import static org.assertj.core.api.Assertions.assertThat;

class ValeriaDemoPasswordBootstrapTest {
    @Test
    void soloPermiteBasesDescoDeDesarrollo() {
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("DESCO_DB_dev")).isTrue();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("DESCO_DB_dev2")).isTrue();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("desco_db_dev2")).isTrue();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("DESCO_DB_prod")).isFalse();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("DESCO_DB_dev3")).isFalse();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida("otro_dev")).isFalse();
        assertThat(ValeriaDemoPasswordBootstrap.esBaseDevPermitida(null)).isFalse();
    }

    @Test
    void requiereBootstrapDemoHabilitadoExpresamente() {
        ConditionalOnProperty condicion = ValeriaDemoPasswordBootstrap.class
                .getAnnotation(ConditionalOnProperty.class);
        assertThat(condicion).isNotNull();
        assertThat(condicion.prefix()).isEqualTo("desco.demo.pos");
        assertThat(condicion.name()).containsExactly("enabled");
        assertThat(condicion.havingValue()).isEqualTo("true");
        assertThat(condicion.matchIfMissing()).isFalse();
    }
}
