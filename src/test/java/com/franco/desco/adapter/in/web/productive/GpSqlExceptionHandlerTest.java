package com.franco.desco.adapter.in.web.productive;

import org.junit.jupiter.api.Test;
import java.sql.SQLException;
import java.util.UUID;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.dao.DataAccessResourceFailureException;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.anyString;
import static org.assertj.core.api.Assertions.assertThat;

class GpSqlExceptionHandlerTest {
    @Test
    void informaSuperficieDisponibleSinExponerErroresInternos() {
        var superficie = new SQLException(
            "La superficie excede las hectáreas disponibles para este predio. Disponible: 3.5000 ha.", "S0001", 51103);
        assertThat(GpSqlExceptionHandler.mensajeValidacion(superficie))
            .isEqualTo("La superficie excede las hectáreas disponibles para este predio. Disponible: 3.5000 ha.");
    }

    @Test
    void noPublicaMensajesSQLNoControlados() {
        var desconocido = new SQLException("SELECT denied: secret_table", "S0001", 51103);
        assertThat(GpSqlExceptionHandler.mensajeValidacion(desconocido))
            .isEqualTo("Revise los datos de la operación.");
    }

    @Test
    void informaValidacionGeograficaAprobada() {
        var geo = new SQLException("El centro poblado seleccionado no corresponde al distrito.", "S0001", 51103);
        assertThat(GpSqlExceptionHandler.mensajeValidacion(geo))
            .isEqualTo("El centro poblado seleccionado no corresponde al distrito.");
    }

    @Test
    void devuelveLaCorrelacionUuidEnLaRespuesta() {
        UUID correlacion = UUID.randomUUID();
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getAttribute(anyString())).thenReturn(correlacion);
        SQLException causa = new SQLException("Datos de parcela inválidos.", "S0001", 51103);
        var ex = new DataAccessResourceFailureException("Error de registro", causa);

        var respuesta = new GpSqlExceptionHandler().database(ex, request);

        assertThat(respuesta.getStatusCode().value()).isEqualTo(400);
        assertThat(respuesta.getBody()).isNotNull();
        assertThat(respuesta.getBody().correlacionId()).isEqualTo(correlacion);
        assertThat(respuesta.getBody().mensaje()).isEqualTo("Datos de parcela inválidos.");
    }
}
