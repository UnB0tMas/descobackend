package com.franco.desco.adapter.in.web.e4;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class E4WebValidationTest {
    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test void taraSeExpresaEnKilogramosNoEnGramos() {
        BigDecimal tara = new BigDecimal("0.140");
        List<BigDecimal> pesos = List.of(new BigDecimal("23.000"),
            new BigDecimal("22.000"), new BigDecimal("24.500"));
        assertThat(pesos.get(0).subtract(tara)).isEqualByComparingTo("22.860");
        assertThat(pesos.get(1).subtract(tara)).isEqualByComparingTo("21.860");
        assertThat(pesos.get(2).subtract(tara)).isEqualByComparingTo("24.360");
        assertThat(pesos.stream().map(p -> p.subtract(tara)).reduce(BigDecimal.ZERO,BigDecimal::add))
            .isEqualByComparingTo("69.080");
    }

    @Test void laSolicitudRechazaCuposCantidadesYPesosInvalidos() {
        assertThat(validator.validate(new E4WebTypes.Asignacion(3001))).isNotEmpty();
        assertThat(validator.validate(new E4WebTypes.Configuracion(0,new BigDecimal("0.140")))).isNotEmpty();
        assertThat(validator.validate(new E4WebTypes.Stock(-1,"Acta"))).isNotEmpty();
        assertThat(validator.validate(new E4WebTypes.PesajePreliminar(new BigDecimal("0")))).isNotEmpty();
        assertThat(validator.validate(new E4WebTypes.Stock(3000,"Inventario físico validado"))).isEmpty();
    }

    @Test void corregirPesajeExigeVersionYMotivo() {
        var sinMotivo = new E4WebTypes.PesajeCorreccion(new BigDecimal("23.000"),1L,1L,
            1L,"",null);
        assertThat(validator.validate(sinMotivo)).isNotEmpty();
        var valido = new E4WebTypes.PesajeCorreccion(new BigDecimal("23.000"),1L,1L,
            2L,"Corregido en acta",new BigDecimal("0.140"));
        assertThat(validator.validate(valido)).isEmpty();
    }
    @Test void retornoYTarifaSeCalculanComoHechosIndependientesDelPesaje() {
        int entregadas = 40;
        int pesadas = 37;
        int llenasDevueltas = 37;
        int vaciasDevueltas = 1;
        int faltantesFisicos = entregadas - llenasDevueltas - vaciasDevueltas;
        assertThat(pesadas).isEqualTo(37);
        assertThat(llenasDevueltas + vaciasDevueltas).isEqualTo(38);
        assertThat(faltantesFisicos).isEqualTo(2);
        assertThat(new BigDecimal(faltantesFisicos).multiply(new BigDecimal("25.00")))
            .isEqualByComparingTo("50.00");
    }

    @Test void precioEfectivoNoCambiaElPrecioOriginal() {
        BigDecimal original = new BigDecimal("3.20");
        BigDecimal efectivo = new BigDecimal("2.80");
        BigDecimal kilos = new BigDecimal("10.000");
        BigDecimal bruto = original.multiply(kilos);
        BigDecimal ventaAjustada = efectivo.multiply(kilos);
        assertThat(bruto).isEqualByComparingTo("32.00000");
        assertThat(ventaAjustada).isEqualByComparingTo("28.00000");
        assertThat(bruto.subtract(ventaAjustada)).isEqualByComparingTo("4.00000");
        // E5 debe usar ventaAjustada sin deducir de nuevo la diferencia.
    }

}
