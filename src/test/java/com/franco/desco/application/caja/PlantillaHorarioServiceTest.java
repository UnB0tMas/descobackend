package com.franco.desco.application.caja;

import org.junit.jupiter.api.Test;
import java.time.LocalTime;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class PlantillaHorarioServiceTest {
    private final PlantillaHorarioRepository repository = mock(PlantillaHorarioRepository.class);
    private final PlantillaHorarioService service = new PlantillaHorarioService(repository);

    @Test
    void guardaUnTurnoSinModificarAsignaciones() {
        when(repository.ejecutar(eq("GUARDAR"), eq(12L), eq(5L), isNull(),
                eq("Turno mañana"), eq(LocalTime.of(7, 0)), eq(LocalTime.of(14, 0))))
                .thenReturn(new PlantillaHorarioRepository.Respuesta(true, "TURNO_OK", "Turno actualizado.", 200, List.of()));

        var resultado = service.guardar(12L, 5L, null, " Turno mañana ", "07:00", "14:00");

        assertThat(resultado.mensaje()).isEqualTo("Turno guardado.");
        verify(repository, times(1)).ejecutar(anyString(), anyLong(), anyLong(), any(), any(), any(), any());
    }

    @Test
    void noEnviaHorasInvalidasALaBase() {
        assertThatThrownBy(() -> service.guardar(12L, 5L, null, "Mañana", "14:00", "07:00"))
                .isInstanceOf(RuntimeException.class);
        verifyNoInteractions(repository);
    }

    @Test
    void conservaErrorFuncionalSinExponerCodigos() {
        when(repository.ejecutar(eq("DESACTIVAR"), eq(12L), eq(5L), eq(40L),
                isNull(), isNull(), isNull()))
                .thenReturn(new PlantillaHorarioRepository.Respuesta(false, "TURNO_NO_EXISTE",
                        "El turno ya no está disponible.", 404, List.of()));

        assertThatThrownBy(() -> service.desactivar(12L, 5L, 40L))
                .hasMessage("El turno ya no está disponible.");
    }
}
