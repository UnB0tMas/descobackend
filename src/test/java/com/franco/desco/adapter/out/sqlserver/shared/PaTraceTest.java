package com.franco.desco.adapter.out.sqlserver.shared;

import org.junit.jupiter.api.Test;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;

import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PaTraceTest {
    @Test
    void respetaElResultadoYNoReintentaUnProcedimiento() {
        AtomicInteger invocations = new AtomicInteger();
        Map<String, Object> result = PaTrace.call("seg.PA_Sesion_Val_Acceso", () -> {
            invocations.incrementAndGet();
            return Map.of("bResultado", false, "cCodigoRespuesta", "SESION_INVALIDA",
                    "cMensaje", "Sesión no válida");
        });

        assertThat(result.get("bResultado")).isEqualTo(false);
        assertThat(invocations).hasValue(1);
    }

    @Test
    void noOcultaLaExcepcionOriginal() {
        IllegalStateException failure = new IllegalStateException("Error de prueba");
        assertThatThrownBy(() -> PaTrace.call("org.PA_Prueba", () -> {
            throw failure;
        })).isSameAs(failure);
    }

    @Test
    void falloFuncionalNoReintentaNiTransformaLaRespuestaOriginal() {
        AtomicInteger attempts = new AtomicInteger();
        AtomicReference<String> detail = new AtomicReference<>();
        Map<String, Object> output = Map.of("bResultado", 0, "cMensaje", "Validación denegada");

        Map<String, Object> returned = PaTrace.call("seg.PA_Validar", () -> {
            attempts.incrementAndGet();
            return output;
        }, result -> false, result -> {
            detail.set("denegada");
            return "denegada";
        });

        assertThat(returned).isSameAs(output);
        assertThat(attempts).hasValue(1);
        assertThat(detail).hasValue("denegada");
    }

    @Test
    void respuestaNulaEsCompatibleConConsultasHistoricas() {
        assertThat(PaTrace.call("org.PA_Consulta", () -> null)).isNull();
    }

    @Test
    void booleanoFalsoYErrorDeAplicacionConservanRetorno() {
        assertThat(PaTrace.call("logistica.PA_Prueba", () -> false)).isFalse();

        AppResult<Void> failure = AppResult.error(
                AppStatus.BAD_REQUEST, "OPERACION_NO_COMPLETADA", "Error funcional"
        );
        assertThat(PaTrace.call("logistica.PA_Prueba", () -> failure)).isSameAs(failure);
    }

    @Test
    void resultadoNuloDeclaradoNoSeConvierteEnExitoFuncional() {
        Map<String, Object> output = new java.util.HashMap<>();
        output.put("@b_resultado", null);
        output.put("cMensaje", "Sin confirmación");

        assertThat(PaTrace.call("org.PA_SinEstado", () -> output)).isSameAs(output);
    }

    @Test
    void normalizaElNombreSinExponerParametros() {
        assertThat(PaTrace.procedureName("{call org.PA_Socio_Ins_Registro(?,?,?)}"))
                .isEqualTo("org.PA_Socio_Ins_Registro");
        assertThat(PaTrace.procedureName("EXEC prod.PA_Planta_Sel_Listado ?,?"))
                .isEqualTo("prod.PA_Planta_Sel_Listado");
    }
}
