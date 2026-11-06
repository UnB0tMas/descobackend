package com.franco.desco.adapter.in.web.fieldtrip;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class E2WebValidationTest {
    @Test void noPermiteFinPrevistoAnteriorAlInicio() {
        var request=new E2WebTypes.SolicitudRequest("Salida",1,
             Instant.parse("2026-11-01T08:00:00Z"),Instant.parse("2026-10-31T20:00:00Z"),
             null,List.of(new E2WebTypes.DestinoRequest(null,"Sector Norte")),List.of());
        assertThat(request.isFechasValidas()).isFalse();
    }
    @Test void permiteFinOpcionalYDestinoNoRegistrado() {
        var request=new E2WebTypes.SolicitudRequest("Salida",1,
             Instant.parse("2026-11-01T08:00:00Z"),null,null,
             List.of(new E2WebTypes.DestinoRequest(null,"Sector Norte")),List.of());
        assertThat(request.isFechasValidas()).isTrue();
        assertThat(request.destinos().getFirst().isValido()).isTrue();
    }
    @Test void lasDecisionesDesfavorablesExigenMotivo() {
        assertThat(new E2WebTypes.DecisionRequest("RECHAZADA",null).isMotivoValido()).isFalse();
        assertThat(new E2WebTypes.DecisionRequest("APROBADA",null).isMotivoValido()).isTrue();
    }
}
