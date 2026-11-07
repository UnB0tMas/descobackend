package com.franco.desco.adapter.out.persistence.fieldtrip;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class E2SqlServerAdapterTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final E2SqlServerAdapter adapter = new E2SqlServerAdapter(jdbc,new JsonMapper());

    @Test void nuncaInvocaSqlSinSesionPublicaValida() {
        var identity = new SessionIdentity(3L,null,1,"jwt");
        var meta = new RequestMetadata(UUID.randomUUID(),UUID.randomUUID(),UUID.randomUUID(),
                "127.0.0.1","/api/v1/salidas-operativas","test","test","test","test");
        var command = new E2Commands.Decidir(1L,null,2L,new E2Commands.DecisionDatos("APROBAR",null));
        var result = adapter.decidir(command,identity,meta);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(401);
        verifyNoInteractions(jdbc);
    }
}
