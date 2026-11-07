package com.franco.desco.adapter.out.sqlserver.shared;

import com.franco.desco.application.access.RoleCommands.GetRole;
import com.franco.desco.application.organization.OrganizationCommands.GetOrganization;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PaPayloadFactoryQueryTest {

    private final JsonMapper jsonMapper = JsonMapper.builder().build();
    private final PaPayloadFactory factory = new PaPayloadFactory(jsonMapper, value -> "hash");

    @Test
    void queryExponeRaicesSemanticasParaDetallesAdministrativos() throws Exception {
        SessionIdentity identity = new SessionIdentity(1L, UUID.randomUUID(), 1, "jti");
        RequestMetadata metadata = new RequestMetadata(
                UUID.randomUUID(), UUID.randomUUID(), null,
                "127.0.0.1", "/test", "test", "test", "test", "device"
        );

        JsonNode organization = jsonMapper.readTree(
                factory.query(identity, metadata, new GetOrganization(5L))
        );
        JsonNode role = jsonMapper.readTree(
                factory.query(identity, metadata, new GetRole(4L))
        );

        assertEquals(5L, organization.path("empresaId").longValue());
        assertEquals(5L, organization.path("filtros").path("empresaId").longValue());
        assertEquals(5L, organization.path("organizacion").path("empresaId").longValue());
        assertEquals(5L, organization.path("empresa").path("empresaId").longValue());

        assertEquals(4L, role.path("rolId").longValue());
        assertEquals(4L, role.path("rol").path("rolId").longValue());
    }

    @Test void mutationPreservaTextoTratamientoDentroDelObjetoSemantico() throws Exception {
        var identity=new SessionIdentity(1L,UUID.randomUUID(),1,"jti");
        var metadata=new RequestMetadata(UUID.randomUUID(),UUID.randomUUID(),null,"127.0.0.1","/test","test","test","test","device");
        var command=new com.franco.desco.application.sanitation.SanitationCommands.Treatment(7L,8L,9L,java.time.Instant.now(),"Aplicar tratamiento","Producto",java.math.BigDecimal.ONE,"ml","Prueba",10L,java.math.BigDecimal.TEN);
        var json=jsonMapper.readTree(factory.mutation(identity,metadata,command));
        assertEquals(7L,json.path("tratamiento").path("casoFitosanitarioId").longValue());
        assertEquals("Aplicar tratamiento",json.path("tratamiento").path("tratamiento").stringValue());
        assertEquals(10L,json.path("tratamiento").path("programacionProductoId").longValue());
        assertEquals(10,json.path("tratamiento").path("cantidadUtilizada").intValue());
    }
}
