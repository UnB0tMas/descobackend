package com.franco.desco.adapter.out.persistence.expediente;

import com.franco.desco.adapter.out.sqlserver.expediente.E1SqlServerAdapter;
import com.franco.desco.application.expediente.E1Commands;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class E1SqlServerAdapterTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final E1SqlServerAdapter adapter = new E1SqlServerAdapter(jdbc, new JsonMapper());

    @Test
    void nuncaEjecutaElProcedimientoSinSesionPublica() {
        var identity = new SessionIdentity(10L, null, 1, "test");
        var metadata = new RequestMetadata(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), "127.0.0.1",
                "/api/v1/expedientes-productivos", "test", "test", "test", "test"
        );

        var result = adapter.getCatalogos(new E1Commands.GetCatalogos(1L), identity, metadata);

        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(401);
        verifyNoInteractions(jdbc);
    }
}
