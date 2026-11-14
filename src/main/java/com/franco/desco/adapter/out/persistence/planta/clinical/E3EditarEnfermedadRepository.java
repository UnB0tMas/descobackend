package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Enfermedad_Upd_Registro. */
@Repository
public final class E3EditarEnfermedadRepository extends E3ClinicalSqlOperation {
    public E3EditarEnfermedadRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"editarEnfermedad","prod.PA_E3_Enfermedad_Upd_Registro");
    }
}
