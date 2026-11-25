package com.franco.desco.adapter.out.sqlserver.report;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.report.port.out.ReportJobEventScopePort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public class ReportJobEventScopeSqlServerAdapter implements ReportJobEventScopePort {
    private static final String PROCEDURE = "reporte.PA_TrabajoEvento_Sel_Uot";
    private final JdbcTemplate jdbc;

    public ReportJobEventScopeSqlServerAdapter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Long findSpecificUot(long usuarioId, UUID sesionPublicaId) {
        return PaTrace.call(PROCEDURE, "CONSULTAR", () -> jdbc.query(
                "{call reporte.PA_TrabajoEvento_Sel_Uot(?,?)}",
                statement -> {
                    statement.setLong(1, usuarioId);
                    statement.setString(2, sesionPublicaId.toString());
                },
                result -> result.next() ? result.getLong("uotId") : null
        ));
    }
}
