package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.auth.port.out.SessionValidationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.util.LinkedHashMap;
import java.util.Map;

@Repository
@Primary
public class SessionValidationSqlServerAdapter
        implements SessionValidationPort {

    private static final String PROCEDURE =
            "seg.PA_Sesion_Sel_Validar";

    private final SqlServerPaExecutor executor;
    private final JsonMapper jsonMapper;

    public SessionValidationSqlServerAdapter(
            SqlServerPaExecutor executor,
            JsonMapper jsonMapper
    ) {
        this.executor = executor;
        this.jsonMapper = jsonMapper;
    }

    @Override
    public boolean isValid(
            SessionIdentity identity,
            String jtiHashHex,
            String ip
    ) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null
                || identity.tokenVersion() == null
                || jtiHashHex == null
                || jtiHashHex.isBlank()) {
            return false;
        }

        Map<String, Object> payload =
                new LinkedHashMap<>();

        payload.put(
                "usuarioId",
                identity.usuarioId()
        );
        payload.put(
                "sesionPublicaId",
                identity.sesionPublicaId()
        );
        payload.put(
                "tokenVersion",
                identity.tokenVersion()
        );
        payload.put(
                "jtiHashHex",
                jtiHashHex.trim()
        );
        payload.put(
                "ip",
                ip == null
                        ? ""
                        : ip.trim()
        );

        PaExecution execution =
                executor.execute(
                        PROCEDURE,
                        Map.of(
                                "cJson",
                                write(payload)
                        )
                );

        return execution.exitoso();
    }

    private String write(
            Map<String, ?> payload
    ) {
        try {
            return jsonMapper.writeValueAsString(
                    payload
            );
        } catch (Exception exception) {
            throw new IllegalStateException(
                    "No se pudo preparar la validación de sesión.",
                    exception
            );
        }
    }
}
