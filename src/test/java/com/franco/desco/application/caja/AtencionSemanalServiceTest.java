package com.franco.desco.application.caja;

import org.junit.jupiter.api.Test;
import java.time.LocalTime;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AtencionSemanalServiceTest {
    private final AtencionSemanalRepository repository = mock(AtencionSemanalRepository.class);
    private final AtencionSemanalService service = new AtencionSemanalService(repository);

    @Test
    void permitePrevisualizarCambiosSinModificarTurnos() {
        var afectado = new AtencionSemanalRepository.Afectado(10L, 3L, "María Torres", 2,
            "07:00", "20:00", "07:00", "16:00", false);
        when(repository.ejecutar(eq("PREVISUALIZAR"), eq(8L), eq(2L), eq("PERSONALIZAR"), eq(2),
            eq(LocalTime.of(7, 0)), eq(LocalTime.of(16, 0)), eq(false), isNull()))
            .thenReturn(new AtencionSemanalRepository.Respuesta(true, "ATENCION_PREVIA", "Consulta realizada.",
                200, List.of(afectado)));
        var resultado = service.ejecutar("PREVISUALIZAR", 8L, 2L, "PERSONALIZAR", 2,
            "07:00", "16:00", false, null);
        assertThat(resultado.afectados()).containsExactly(afectado);
    }

    @Test
    void noAceptaHorasInvalidas() {
        assertThatThrownBy(() -> service.ejecutar("APLICAR", 8L, 2L, "GENERAL", null,
            "20:00", "07:00", true, null)).isInstanceOf(AtencionSemanalService.Rechazo.class);
        verifyNoInteractions(repository);
    }

    @Test
    void heredarSoloSePermiteParaUnDia() {
        assertThatThrownBy(() -> service.ejecutar("APLICAR", 8L, 2L, "HEREDAR", null,
            null, null, false, null)).isInstanceOf(AtencionSemanalService.Rechazo.class);
        verifyNoInteractions(repository);
    }

    @Test
    void noTrataErrorFuncionalComoExito() {
        when(repository.ejecutar(eq("APLICAR"), anyLong(), anyLong(), eq("PERSONALIZAR"), eq(1),
            any(), any(), eq(false), isNull()))
            .thenReturn(new AtencionSemanalRepository.Respuesta(false, "ATENCION_CONFLICTO",
                "Hay empleados con horarios fuera de la nueva atención.", 409, List.of()));
        assertThatThrownBy(() -> service.ejecutar("APLICAR", 8L, 2L, "PERSONALIZAR", 1,
            "07:00", "16:00", false, null)).isInstanceOf(AtencionSemanalService.Rechazo.class);
    }

    @Test
    void previsualizaDiasSeleccionadosSinDuplicar() {
        var lunes = new AtencionSemanalRepository.Afectado(10L, 3L, "María Torres", 1,
            "07:00", "20:00", "07:00", "16:00", false);
        var miercoles = new AtencionSemanalRepository.Afectado(20L, 4L, "Rosa Pinto", 3,
            "07:00", "20:00", "07:00", "16:00", false);
        when(repository.ejecutar(eq("PREVISUALIZAR"), eq(8L), eq(2L), eq("PERSONALIZAR"), eq(1),
            eq(LocalTime.of(7, 0)), eq(LocalTime.of(16, 0)), eq(false), isNull()))
            .thenReturn(new AtencionSemanalRepository.Respuesta(true, "ATENCION_PREVIA", "Consulta realizada.",
                200, List.of(lunes)));
        when(repository.ejecutar(eq("PREVISUALIZAR"), eq(8L), eq(2L), eq("PERSONALIZAR"), eq(3),
            eq(LocalTime.of(7, 0)), eq(LocalTime.of(16, 0)), eq(false), isNull()))
            .thenReturn(new AtencionSemanalRepository.Respuesta(true, "ATENCION_PREVIA", "Consulta realizada.",
                200, List.of(miercoles)));
        var resultado = service.ejecutarLote("PREVISUALIZAR", 8L, 2L, List.of(3, 1),
            "07:00", "16:00", false, null);
        assertThat(resultado.afectados()).containsExactly(lunes, miercoles);
    }

    @Test
    void rechazaDiasRepetidosAntesDeConsultar() {
        assertThatThrownBy(() -> service.ejecutarLote("APLICAR", 8L, 2L, List.of(1, 1),
            "07:00", "16:00", false, null)).isInstanceOf(AtencionSemanalService.Rechazo.class);
        verifyNoInteractions(repository);
    }
}
