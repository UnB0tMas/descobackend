package com.franco.desco.domain.expediente;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
class E1ModelsTest {
 @Test void expedienteNuevoEntregaTodasLasColeccionesVacias() {
  var e=new E1Models.Expediente(1L,"P1","Nuevo",null,null,null,null,null,null,null,null,null,false,null,null,null,null,null,null);
  assertThat(e.titulares()).isEmpty();assertThat(e.cultivos()).isEmpty();assertThat(e.crianzas()).isEmpty();
  assertThat(e.historial()).isEmpty();assertThat(e.censos()).isEmpty();assertThat(e.conteos()).isEmpty();
 }
}
