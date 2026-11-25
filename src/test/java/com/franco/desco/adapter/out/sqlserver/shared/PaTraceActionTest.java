package com.franco.desco.adapter.out.sqlserver.shared;

import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PaTraceActionTest {

    @Test
    void identificaAccionesSinModificarElNombreRealDelPA() {
        assertThat(PaTrace.procedureName("{call campo.PA_SalidaOperativaE2_Ejecutar(?,?,?)}"))
                .isEqualTo("campo.PA_SalidaOperativaE2_Ejecutar");
        assertThat(PaTrace.operationName("prod.PA_Parcela_Sel_Listado"))
                .isEqualTo("CONSULTAR");
        assertThat(PaTrace.operationName("logistica.PA_Bien_Ins_Registro"))
                .isEqualTo("REGISTRAR");
        assertThat(PaTrace.operationName("logistica.PA_Bien_Upd_Estado"))
                .isEqualTo("ACTUALIZAR");
    }

    @Test
    void ejecutarConAccionExplicitaMantieneRespuestaYUnaSolaInvocacion() {
        AtomicInteger executions = new AtomicInteger();
        Map<String, Object> output = Map.of("bResultado", false,
                "cCodigoRespuesta", "ACCION_DENEGADA", "cMensaje", "No autorizado");
        assertThat(PaTrace.call("campo.PA_SalidaOperativaE2_Ejecutar", "DECIDIR", () -> {
            executions.incrementAndGet();
            return output;
        })).isSameAs(output);
        assertThat(executions).hasValue(1);
    }

    @Test
    void noOcultaExcepcionesNiTransformaElContrato() {
        IllegalArgumentException failure = new IllegalArgumentException("simulación");
        assertThatThrownBy(() -> PaTrace.call("campo.PA_SalidaOperativaE2_Ejecutar",
                "SOLICITAR", () -> { throw failure; })).isSameAs(failure);
    }
}
