package com.franco.desco.adapter.out.persistence.e4;

import com.franco.desco.application.e4.E4Commands;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.json.JsonMapper;
import java.util.UUID;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class E4SqlServerAdapterTest {
    @Test void impideEjecutarElPAEnAusenciaDeSesionAutorizada() {
        var jdbc = mock(JdbcTemplate.class);
        var adapter = new E4SqlServerAdapter(jdbc,new JsonMapper());
        var identidad = new SessionIdentity(1L,null,1,"jwt");
        var metadata = new RequestMetadata(UUID.randomUUID(),UUID.randomUUID(),UUID.randomUUID(),
            "127.0.0.1","/api/v1/apappss/acopio-e4","test","test","test","test");
        var command = new E4Commands.Execute("ASIGNAR",null,1L,null,null,null,40);
        var result = adapter.execute(command,identidad,metadata,String.class);
        assertThat(result.exitoso()).isFalse();
        assertThat(result.httpSugerido()).isEqualTo(401);
        verifyNoInteractions(jdbc);
    }
}
