package com.franco.desco.adapter.out.sqlserver.auth;

import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlValues;
import com.franco.desco.application.auth.port.out.SessionValidationPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.sql.Types;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class SessionValidationSqlServerAdapter
        implements SessionValidationPort {

    private final SqlServerPaExecutor executor;
    private final SimpleJdbcCall validateSessionCall;

    public SessionValidationSqlServerAdapter(
            SqlServerPaFactory factory,
            SqlServerPaExecutor executor
    ) {
        this.executor = executor;

        /*
         * Esta llamada es crítica y tiene contrato estable:
         *
         *   @cJson       NVARCHAR(MAX)
         *   @bResultado  BIT OUTPUT
         *   @cMensaje    NVARCHAR(300) OUTPUT
         *
         * Se desactiva la autodetección de metadatos para que Spring JDBC
         * no intente resolver parámetros internos o de salida a partir del
         * catálogo del driver. De esta forma la ejecución queda determinista
         * y se eliminan los avisos de CallMetaDataContext para este PA.
         */
        this.validateSessionCall =
                factory.call(
                                "seg",
                                "PA_Sesion_Sel_Validar"
                        )
                        .withoutProcedureColumnMetaDataAccess()
                        .declareParameters(
                                new SqlParameter(
                                        "cJson",
                                        Types.NVARCHAR
                                ),
                                new SqlOutParameter(
                                        "bResultado",
                                        Types.BIT
                                ),
                                new SqlOutParameter(
                                        "cMensaje",
                                        Types.NVARCHAR
                                )
                        );
    }

    @Override
    public boolean isValid(
            SessionIdentity identity,
            String jtiHashHex,
            String ip
    ) {
        if (
                identity == null
                || identity.usuarioId() == null
                || identity.sesionPublicaId() == null
                || identity.tokenVersion() == null
        ) {
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
                jtiHashHex
        );
        payload.put(
                "ip",
                ip
        );

        Map<String, Object> result =
                executor.executeJson(
                        validateSessionCall,
                        payload
                );

        return SqlValues.bool(
                result,
                "bResultado"
        );
    }
}
