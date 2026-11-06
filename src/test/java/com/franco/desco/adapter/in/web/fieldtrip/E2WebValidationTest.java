package com.franco.desco.adapter.in.web.fieldtrip;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class E2WebValidationTest {
    private static final Instant NOV_1 = Instant.parse("2026-11-01T08:00:00Z");
    private static final Instant OCT_31 = Instant.parse("2026-10-31T20:00:00Z");

    @Test void noPermiteFinPrevistoAnteriorAlInicio() {
        var request = new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,OCT_31,null,
                List.of(new E2WebTypes.DestinoRequest(10L,null,"Supervisión")),List.of(),List.of(),false);
        assertThat(request.isFechasValidas()).isFalse();
    }
    @Test void exigeFinAlEnviarYExigePredioReal() {
        var request = new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,null,null,
                List.of(new E2WebTypes.DestinoRequest(10L,null,"Supervisión")),List.of(),List.of(),false);
        assertThat(request.isFechasValidas()).isFalse();
        assertThat(request.destinos().getFirst().isValido()).isTrue();
        assertThat(new E2WebTypes.DestinoRequest(null,"Libre","Visita").isValido()).isFalse();
    }
    @Test void correccionTambienValidaOrdenDeFechas() {
        var correction = new E2WebTypes.CorreccionRequest("Revisada",null,1,NOV_1,OCT_31,
                List.of(new E2WebTypes.DestinoRequest(11L,null,"Control sanitario")),List.of(),List.of(),true);
        assertThat(correction.isFechasValidas()).isFalse();
    }
    @Test void borradorAdmiteDestinosPendientes() {
        var draft=new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,null,null,
            List.of(),List.of(),List.of(),true);
        assertThat(draft.isDestinosValidos()).isTrue();
        var send=new E2WebTypes.SolicitudRequest("Salida",1,NOV_1,null,null,
            List.of(),List.of(),List.of(),false);
        assertThat(send.isDestinosValidos()).isFalse();
    }
    @Test void correccionDeBorradorPuedeGuardarseSinDestinos() {
        var draft=new E2WebTypes.CorreccionRequest("Salida",null,1,NOV_1,null,
            List.of(),List.of(),List.of(),false);
        assertThat(draft.isDestinosValidos()).isTrue();
        var sent=new E2WebTypes.CorreccionRequest("Salida",null,1,NOV_1,null,
            List.of(),List.of(),List.of(),true);
        assertThat(sent.isDestinosValidos()).isFalse();
    }
    @Test void lasDecisionesDesfavorablesExigenMotivo() {
        assertThat(new E2WebTypes.DecisionRequest("RECHAZADA",null).isMotivoValido()).isFalse();
        assertThat(new E2WebTypes.DecisionRequest("OBSERVADA","Revisar destino").isMotivoValido()).isTrue();
        assertThat(new E2WebTypes.DecisionRequest("APROBADA",null).isMotivoValido()).isTrue();
    }
    @Test void motivoDeBorradorEsOpcionalEnContratoHttp() {
        try (var factory = jakarta.validation.Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            assertThat(validator.validate(new E2WebTypes.CancelarRequest(null))).isEmpty();
            assertThat(validator.validate(new E2WebTypes.CancelarRequest(""))).isEmpty();
            assertThat(validator.validate(new E2WebTypes.CancelarRequest("x".repeat(1201)))).isNotEmpty();
        }
    }

}
