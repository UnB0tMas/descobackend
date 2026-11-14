package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Planta_Sel_AnalisisSanitario. */
@Repository
public final class E3AnalisisFitosanitarioRepository extends E3ClinicalSqlOperation {
    public E3AnalisisFitosanitarioRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"analisisFitosanitario","prod.PA_E3_Planta_Sel_AnalisisSanitario");
    }
}
