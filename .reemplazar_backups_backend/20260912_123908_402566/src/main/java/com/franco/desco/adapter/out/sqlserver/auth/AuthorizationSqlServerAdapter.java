package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.auth.port.out.AuthorizationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class AuthorizationSqlServerAdapter
        implements AuthorizationPort {

    private final SqlServerPaExecutor executor;
    private final SimpleJdbcCall validatePermissionCall;

    public AuthorizationSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor
    ) {
        this.executor = executor;
        this.validatePermissionCall = factory.call(
                "seg",
                "PA_Autorizacion_Sel_ValidarPermiso"
        );
    }

    @Override
    public boolean hasPermission(
            SessionIdentity identity,
            String permissionCode
    ) {
        Map<String, Object> result =
                executor.execute(
                        validatePermissionCall,
                        Map.of(
                                "nUsuarioId",
                                identity.usuarioId(),
                                "gSesionPublicaId",
                                identity.sesionPublicaId(),
                                "cCodigoPermiso",
                                permissionCode
                        )
                );

        return SqlValues.bool(
                result,
                "bAutorizado"
        );
    }
}
