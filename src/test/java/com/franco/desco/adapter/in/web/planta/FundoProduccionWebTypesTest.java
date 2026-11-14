package com.franco.desco.adapter.in.web.planta;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.LocalDate;
import static org.assertj.core.api.Assertions.assertThat;

class FundoProduccionWebTypesTest {
    @Test void noPermitePeriodoFueraDelAnio() {
        var datos = new FundoProduccionWebTypes.Guardar(2026,0L,
                LocalDate.of(2026,11,1),LocalDate.of(2027,1,1),
                "DISPONIBLE",new BigDecimal("100.000"),null);
        assertThat(datos.isPeriodoValido()).isFalse();
    }
    @Test void noPermiteDisponibilidadPositivaSinKilos() {
        var datos = new FundoProduccionWebTypes.Guardar(2026,0L,
                LocalDate.of(2026,11,1),LocalDate.of(2026,11,30),
                "PARCIAL",BigDecimal.ZERO,null);
        assertThat(datos.isCantidadValida()).isFalse();
    }
    @Test void aceptaFundoSinProduccionConKilosCero() {
        var datos = new FundoProduccionWebTypes.Guardar(2026,0L,
                LocalDate.of(2026,11,1),LocalDate.of(2026,11,30),
                "NO_DISPONIBLE",BigDecimal.ZERO,null);
        assertThat(datos.isCantidadValida()).isTrue();
    }
}
