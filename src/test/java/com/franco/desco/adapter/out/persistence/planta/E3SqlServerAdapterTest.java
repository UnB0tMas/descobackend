package com.franco.desco.adapter.out.persistence.planta;

import com.franco.desco.application.planta.E3Commands.Execute;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class E3SqlServerAdapterTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final E3SqlServerAdapter adapter = new E3SqlServerAdapter(jdbc, new JsonMapper());
    private final Execute command = new Execute("LOTE", 3L, 4L, 5L, null,
            null, null, null, null, null, null);
    private final RequestMetadata metadata = new RequestMetadata(UUID.randomUUID(), UUID.randomUUID(),
            UUID.randomUUID(), "127.0.0.1", "/api/v1/apappss/plantas/lotes", "test", "test", "test", "test");

    @Test
    void noEjecutaStoredProcedureSinSesionPublica() {
        var result = adapter.execute(command, new SessionIdentity(1L, null, 1, "jwt"), metadata, String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(401);
        verifyNoInteractions(jdbc);
    }

    @Test
    void noEjecutaStoredProcedureSinMetadatos() {
        var result = adapter.execute(command, new SessionIdentity(1L, UUID.randomUUID(), 1, "jwt"), null, String.class);
        assertThat(result.exitoso()).isFalse();
        verifyNoInteractions(jdbc);
    }
}
