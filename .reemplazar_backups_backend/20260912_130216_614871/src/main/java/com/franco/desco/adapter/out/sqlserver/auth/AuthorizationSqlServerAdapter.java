package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.PaExecution;
import com.franco.desco.adapter.out.sqlserver.shared.PaResultSets;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.auth.port.out.AuthorizationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Repository;

import java.util.Map;

@Repository
@Primary
public final class AuthorizationSqlServerAdapter
        implements AuthorizationPort {

    private static final String PROCEDURE =
            "seg.PA_Autorizacion_Sel_ValidarPermiso";

    private final SqlServerPaExecutor executor;

    public AuthorizationSqlServerAdapter(
            SqlServerPaExecutor executor
    ) {
        this.executor = executor;
    }

    @Override
    public boolean hasPermission(
            SessionIdentity identity,
            String permissionCode
    ) {
        if (identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null
                || permissionCode == null
                || permissionCode.isBlank()) {
            return false;
        }

        PaExecution execution =
                executor.execute(
                        PROCEDURE,
                        Map.of(
                                "usuarioId",
                                identity.usuarioId(),
                                "sesionPublicaId",
                                identity.sesionPublicaId(),
                                "codigoPermiso",
                                permissionCode.trim()
                        )
                );

        return execution.exitoso()
                && PaResultSets.bool(
                execution.outputs(),
                "autorizado"
        );
    }
}
