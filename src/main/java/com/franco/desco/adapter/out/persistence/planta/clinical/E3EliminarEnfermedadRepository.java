package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Enfermedad_Upd_Eliminar. */
@Repository
public final class E3EliminarEnfermedadRepository extends E3ClinicalSqlOperation {
    public E3EliminarEnfermedadRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"eliminarEnfermedad","prod.PA_E3_Enfermedad_Upd_Eliminar");
    }
}
