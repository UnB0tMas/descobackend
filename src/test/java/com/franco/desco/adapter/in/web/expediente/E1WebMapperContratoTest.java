package com.franco.desco.adapter.in.web.expediente;

import com.franco.desco.domain.expediente.E1Models;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class E1WebMapperContratoTest {
    private final E1WebMapper mapper = new E1WebMapper();

    @Test
    void conservaLaUbicacionYLasColeccionesDelExpediente() {
        var expediente = new E1Models.Expediente(
                15L, "PRE-15", "Fundo Paltos", "050101", "Cerca del canal",
                42L, "Centro Poblado Central",
                new BigDecimal("-14.123456"), new BigDecimal("-73.654321"),
                new BigDecimal("2.5000"), new BigDecimal("2.0000"),
                "GOTEO", true,
                List.of(), List.of(), List.of(), List.of(), List.of(), List.of()
        );

        var respuesta = mapper.response(expediente);

        assertThat(respuesta.predioId()).isEqualTo(15L);
        assertThat(respuesta.centroPobladoId()).isEqualTo(42L);
        assertThat(respuesta.centroPoblado()).isEqualTo("Centro Poblado Central");
        assertThat(respuesta.latitud()).isEqualByComparingTo("-14.123456");
        assertThat(respuesta.longitud()).isEqualByComparingTo("-73.654321");
        assertThat(respuesta.areaTotalHa()).isEqualByComparingTo("2.5000");
        assertThat(respuesta.areaCultivableHa()).isEqualByComparingTo("2.0000");
        assertThat(respuesta.fichaCompleta()).isTrue();
        assertThat(respuesta.titulares()).isEmpty();
        assertThat(respuesta.cultivos()).isEmpty();
        assertThat(respuesta.crianzas()).isEmpty();
        assertThat(respuesta.historial()).isEmpty();
        assertThat(respuesta.censos()).isEmpty();
        assertThat(respuesta.conteos()).isEmpty();
    }
}
