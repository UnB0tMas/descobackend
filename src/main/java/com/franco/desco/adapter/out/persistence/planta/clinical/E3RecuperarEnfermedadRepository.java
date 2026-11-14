package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Enfermedad_Upd_Recuperar. */
@Repository
public final class E3RecuperarEnfermedadRepository extends E3ClinicalSqlOperation {
    public E3RecuperarEnfermedadRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"recuperarEnfermedad","prod.PA_E3_Enfermedad_Upd_Recuperar");
    }
}
