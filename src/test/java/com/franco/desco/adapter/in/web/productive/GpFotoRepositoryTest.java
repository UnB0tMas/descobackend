package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class GpFotoRepositoryTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final GpRepository gp = mock(GpRepository.class);
    private final GpFotoRepository repo = new GpFotoRepository(jdbc, gp);
    private final SessionIdentity usuario = new SessionIdentity(1L, UUID.randomUUID(), 1, "jwt");

    @Test
    void cargaAdmiteAccesoValidadoPorLaMismaReglaDelSeguimiento() {
        when(gp.predioEvento(2L, 12L)).thenReturn(25L);
        when(jdbc.queryForObject(anyString(), eq(Long.class),
                eq(usuario.sesionPublicaId()), eq(usuario.usuarioId()), eq(2L), eq(12L),
                eq("imagen.png"), eq("image/png"), eq(100L)))
                .thenReturn(91L);

        Long fotoId = repo.registrar(usuario, 2L, 12L, "imagen.png", "image/png", 100L);

        assertEquals(91L, fotoId);
        verify(gp).verificarVisita(usuario, 2L, 25L);
    }

    @Test
    void cargaDenegadaNoRegistraFotoNiEvitaLaValidacionDeVisita() {
        when(gp.predioEvento(2L, 12L)).thenReturn(25L);
        doThrow(new AccessDeniedException("Acceso no autorizado"))
                .when(gp).verificarVisita(usuario, 2L, 25L);

        assertThrows(AccessDeniedException.class,
                () -> repo.registrar(usuario, 2L, 12L, "imagen.png", "image/png", 100L));
        verifyNoInteractions(jdbc);
    }
}
