package com.franco.desco.adapter.in.web.fieldtrip;

import org.junit.jupiter.api.Test;
import jakarta.validation.Validation;

import java.time.Instant;
import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class SalidaDocumentalWebValidationTest {
    private static final Instant INICIO = Instant.parse("2026-11-23T08:00:00Z");
    private static final Instant FIN = Instant.parse("2026-11-23T16:00:00Z");

    @Test
    void exigeDestinoRealYActividadAntesDeEnviar() {
        var solicitud = new SalidaDocumentalWebTypes.Solicitud("Visita técnica", 1, INICIO, FIN,
                "Evaluar cultivos", List.of(new E2WebTypes.DestinoRequest(12L, null, "")),
                List.of(), List.of(), List.of());
        assertThat(solicitud.isDestinosCompletos()).isFalse();
        assertThat(solicitud.isFechasValidas()).isTrue();
    }

    @Test
    void exigeFinalPosteriorAlInicio() {
        var solicitud = new SalidaDocumentalWebTypes.Solicitud("Visita técnica", 1, INICIO, INICIO,
                null, List.of(new E2WebTypes.DestinoRequest(12L, null, "Aplicación")),
                List.of(), List.of(), List.of());
        assertThat(solicitud.isFechasValidas()).isFalse();
        assertThat(solicitud.isDestinosCompletos()).isTrue();
    }

    @Test
    void rechazoYObservacionExigenMotivo() {
        assertThat(new E2WebTypes.DecisionRequest("OBSERVADA", "").isMotivoValido()).isFalse();
        assertThat(new E2WebTypes.DecisionRequest("RECHAZADA", "Motivo documentado").isMotivoValido()).isTrue();
        assertThat(new E2WebTypes.DecisionRequest("APROBADA", null).isMotivoValido()).isTrue();
    }

    @Test
    void validaCadaElementoDeLasColeccionesAnidadas() {
        var solicitud = new SalidaDocumentalWebTypes.Solicitud(
                "Visita técnica", 1, INICIO, FIN, "Evaluar cultivos",
                List.of(new E2WebTypes.DestinoRequest(null, "Sector", "Inspección")),
                List.of(new E2WebTypes.BienRequest(null, null, BigDecimal.ONE)),
                List.of(new E2WebTypes.ParticipanteRequest(null, "Responsable")), List.of());
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var campos = factory.getValidator().validate(solicitud).stream()
                    .map(error -> error.getPropertyPath().toString()).toList();
            assertThat(campos).anyMatch(campo -> campo.startsWith("destinos"));
            assertThat(campos).anyMatch(campo -> campo.startsWith("bienes"));
            assertThat(campos).anyMatch(campo -> campo.startsWith("participantes"));
        }
    }
}
