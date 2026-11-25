package com.franco.desco.adapter.out.persistence.productive;

import com.franco.desco.adapter.out.sqlserver.shared.PaTrace;
import com.franco.desco.application.productive.summary.GpResumenDto;
import com.franco.desco.application.productive.summary.GpResumenPort;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

@Repository
public class GpResumenSqlAdapter implements GpResumenPort {
    private final JdbcTemplate jdbc;
    private final JsonMapper json;

    public GpResumenSqlAdapter(JdbcTemplate jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public GpResumenDto consultar(SessionIdentity usuario, long uotId, long actividadId,
                                 String periodo, String tipoEvento) {
        return PaTrace.call("prod.PA_GP_Resumen_Sel_Indicadores", () -> {
            String datos = jdbc.queryForObject(
                    "EXEC prod.PA_GP_Resumen_Sel_Indicadores ?,?,?,?,?,?",
                    String.class, usuario.sesionPublicaId(), usuario.usuarioId(),
                    uotId, actividadId, periodo, tipoEvento);
            return json.readValue(datos, GpResumenDto.class);
        });
    }
}
