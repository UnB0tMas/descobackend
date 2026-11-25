package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;
import tools.jackson.databind.json.JsonMapper;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GpRepositoryAccesoAdministradorTest {
    private final JdbcTemplate db = mock(JdbcTemplate.class);
    private final GpRepository repository = new GpRepository(db, new JsonMapper());
    private final UUID sesion = UUID.randomUUID();
    private final SessionIdentity usuario = new SessionIdentity(1L, sesion, 2, "jwt");

    @Test
    void autorizacionEfectivaPermiteRegistrar() {
        when(db.queryForObject(contains("prod.PA_GP_Actuacion_Sel_Autorizacion"), eq(Boolean.class),
                eq(sesion), eq(1L), eq(2L), eq(10L))).thenReturn(true);

        assertThatCode(() -> verificarVisita()).doesNotThrowAnyException();
    }

    @Test
    void sinAutorizacionRechazaRegistro() {
        when(db.queryForObject(contains("prod.PA_GP_Actuacion_Sel_Autorizacion"), eq(Boolean.class),
                eq(sesion), eq(1L), eq(2L), eq(10L))).thenReturn(false);

        assertThatThrownBy(this::verificarVisita).isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void visitaIniciadaPermiteElRegistroOrdinario() {
        when(db.queryForObject(contains("prod.PA_GP_Actuacion_Sel_Autorizacion"), eq(Boolean.class),
                eq(sesion), eq(1L), eq(2L), eq(10L))).thenReturn(true);

        assertThatCode(() -> verificarVisita()).doesNotThrowAnyException();
    }

    private void verificarVisita() {
        ReflectionTestUtils.invokeMethod(repository, "verificarVisita", usuario, 2L, 10L);
    }
}
