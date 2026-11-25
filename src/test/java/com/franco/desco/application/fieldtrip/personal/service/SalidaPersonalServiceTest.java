package com.franco.desco.application.fieldtrip.personal.service;

import com.franco.desco.application.fieldtrip.personal.SalidaPersonalQuery;
import com.franco.desco.application.fieldtrip.personal.port.out.SalidaPersonalPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.fieldtrip.SalidaPersonalModels;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class SalidaPersonalServiceTest {
    private final SalidaPersonalPersistencePort persistence=mock(SalidaPersonalPersistencePort.class);
    private final SalidaPersonalService service=new SalidaPersonalService(persistence);
    private final SessionIdentity usuario=new SessionIdentity(101L,UUID.randomUUID(),1,"sesion");
    private final RequestMetadata metadata=new RequestMetadata(UUID.randomUUID(),UUID.randomUUID(),
            UUID.randomUUID(),"127.0.0.1","/api/v1/salidas-tecnicas/mis-salidas", "pruebas","","","");

    @Test
    void noConsultaCuandoLaPaginacionEsInvalida() {
        var filtros=new SalidaPersonalQuery("LISTAR",2L,null,null,null,0,200);
        var resultado=service.listar(filtros,usuario,metadata);
        assertThat(resultado.exitoso()).isFalse();
        verifyNoInteractions(persistence);
    }

    @Test
    void conservaLaIdentidadDeSesionYLaPaginacionEnLaConsulta() {
        var filtros=new SalidaPersonalQuery("LISTAR",2L,null,"riego","SOLICITADA",3,20);
        var pagina=new SalidaPersonalModels.Lista(0L,List.of());
        when(persistence.consultar(eq(filtros),eq(usuario),eq(metadata),eq(SalidaPersonalModels.Lista.class)))
            .thenReturn(PersistenceResult.ok("SALIDA_PERSONAL_OK","Consulta realizada.",200,pagina));

        var resultado=service.listar(filtros,usuario,metadata);
        assertThat(resultado.exitoso()).isTrue();
        assertThat(resultado.datos()).isEqualTo(pagina);
        verify(persistence).consultar(eq(filtros),eq(usuario),eq(metadata),eq(SalidaPersonalModels.Lista.class));
    }

    @Test
    void noConsultaActividadConSalidaInvalida() {
        var filtros=new SalidaPersonalQuery("DETALLE",2L,-1L,null,null,null,null);
        var resultado=service.detalle(filtros,usuario,metadata);
        assertThat(resultado.exitoso()).isFalse();
        verifyNoInteractions(persistence);
    }

    @Test
    void propagaLaDenegacionDelProcedimientoSinExponerDatos() {
        var filtros=new SalidaPersonalQuery("DETALLE",2L,90L,null,null,null,null);
        when(persistence.consultar(eq(filtros),eq(usuario),eq(metadata),eq(SalidaPersonalModels.Detalle.class)))
            .thenReturn(PersistenceResult.error("SALIDA_PERSONAL_VALIDACION","Esta salida no está disponible.",404));
        var resultado=service.detalle(filtros,usuario,metadata);
        assertThat(resultado.exitoso()).isFalse();
        assertThat(resultado.estado()).isEqualTo(AppStatus.NOT_FOUND);
        assertThat(resultado.datos()).isNull();
    }
}
