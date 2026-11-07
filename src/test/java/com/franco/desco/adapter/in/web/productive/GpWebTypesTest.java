package com.franco.desco.adapter.in.web.productive;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class GpWebTypesTest {
    @Test void parcelaExigeCoordenadasCompletas() {
        var q=new GpWebTypes.ParcelaAlta(1L,"Parcela",new BigDecimal("1.5"),"050101",null,new BigDecimal("-15.1"),null);
        assertThat(q.isGeoposicionValida()).isFalse();
    }
    @Test void crianzaRequiereCantidadYSuperficieExactas() {
        assertThat(new GpWebTypes.ActividadAlta(1L,"CRIANZA",null,4,null,null,12,null,null,List.of(),List.of()).isValida()).isFalse();
        assertThat(new GpWebTypes.ActividadAlta(1L,"CRIANZA",null,4,null,null,12,null,new BigDecimal("250"),List.of(),List.of()).isValida()).isTrue();
        assertThat(new GpWebTypes.ActividadAlta(1L,"CRIANZA",null,4,null,null,null,null,new BigDecimal("250"),List.of(),List.of()).isValida()).isFalse();
    }
    @Test void cultivoSoloAdmiteSuperficieExacta() {
        assertThat(new GpWebTypes.ActividadAlta(1L,"CULTIVO",3,null,null,null,null,new BigDecimal("25"),null,List.of(),List.of()).isValida()).isFalse();
        assertThat(new GpWebTypes.ActividadAlta(1L,"CULTIVO",3,null,null,null,null,null,new BigDecimal("25"),List.of(),List.of()).isValida()).isTrue();
    }
    @Test void razaNoAdmiteCantidadAproximada() {
        assertThat(new GpWebTypes.RazaConteo(1,null,5,null).isMedicionValida()).isTrue();
        assertThat(new GpWebTypes.RazaConteo(1,5,null,null).isMedicionValida()).isFalse();
        assertThat(new GpWebTypes.RazaConteo(1,null,null,null).isMedicionValida()).isFalse();
    }
    @Test void censoValidaSuperficieYConteosCompatibles() {
        assertThat(new GpWebTypes.CensoAlta(null,12,null,null,List.of(),List.of(),"Actualizado",null).isMedicionValida()).isFalse();
        assertThat(new GpWebTypes.CensoAlta(null,12,null,new BigDecimal("400"),List.of(),List.of(),"Compra",null).isMedicionValida()).isTrue();
        assertThat(new GpWebTypes.CensoAlta(null,null,null,new BigDecimal("25"),List.of(),List.of(),"Actualizado",null).isMedicionValida()).isTrue();
        assertThat(new GpWebTypes.CensoAlta(10,null,null,null,List.of(),List.of(),"Actualizado",null).isMedicionValida()).isFalse();
    }
    @Test void cantidadAfectadaTieneIndicadorDeAproximacion() {
        var q=new GpWebTypes.EventoAlta("INCIDENCIA",2,null,null,"Enfermedad",null,null,true);
        assertThat(q.isCantidadValida()).isFalse();
    }

    @Test void censoPermiteCeroParaCerrarPeroAltaDeCrianzaExigeAnimales() {
        assertThat(new GpWebTypes.CensoAlta(null,0,null,new BigDecimal("400"),List.of(),List.of(),"Cierre de crianza",1L).isMedicionValida()).isTrue();
        assertThat(new GpWebTypes.CensoAlta(null,-1,null,new BigDecimal("400"),List.of(),List.of(),"Cantidad negativa",1L).isMedicionValida()).isFalse();
        assertThat(new GpWebTypes.ActividadAlta(1L,"CRIANZA",null,4,null,null,0,null,new BigDecimal("250"),List.of(),List.of()).isValida()).isFalse();
    }
}
