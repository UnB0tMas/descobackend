package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.domain.auth.AccessContext;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuthSqlServerAdapterTest {

    @Test
    void mapsLegacyAccessContextAliasesWithoutLosingCodes() {
        AuthSqlServerAdapter adapter = new AuthSqlServerAdapter(
                null,
                new DatabaseRecordMapper(),
                null
        );

        List<List<Map<String, Object>>> resultSets = List.of(
                List.of(Map.of(
                        "usuarioId", 1L,
                        "nombreUsuario", "admin",
                        "estadoCuenta", "ACTIVA",
                        "tokenVersion", 2
                )),
                List.of(Map.of(
                        "rolId", 1L,
                        "codigoRol", "ADMINISTRADOR",
                        "nombreRol", "Administrador",
                        "requiereSegundoFactor", true
                )),
                List.of(Map.of(
                        "moduloId", 21,
                        "codigoModulo", "INICIO",
                        "nombreModulo", "Inicio",
                        "orden", 10,
                        "visibleMenu", true,
                        "esGrupo", false
                )),
                List.of(Map.of(
                        "permisoId", 128L,
                        "moduloId", 21,
                        "codigoModulo", "INICIO",
                        "codigoPermiso", "INICIO_LISTAR",
                        "nombrePermiso", "Listar inicio",
                        "accion", "LISTAR",
                        "esSensible", false,
                        "requiereMotivo", false
                ))
        );

        AccessContext context = adapter.mapAccessContext(resultSets);

        assertNotNull(context);
        assertEquals("ADMINISTRADOR", context.roles().getFirst().codigo());
        assertEquals("Administrador", context.roles().getFirst().nombre());
        assertEquals("INICIO", context.modulos().getFirst().codigo());
        assertEquals("Inicio", context.modulos().getFirst().nombre());
        assertEquals("INICIO_LISTAR", context.permisos().getFirst().codigo());
        assertEquals("Listar inicio", context.permisos().getFirst().nombre());
        assertFalse(context.permisos().getFirst().sensible());
        assertTrue(context.roles().getFirst().requiereSegundoFactor());
    }
}
