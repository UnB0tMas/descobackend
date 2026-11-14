package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Enfermedad_Sel_Listado. */
@Repository
public final class E3ListarEnfermedadesRepository extends E3ClinicalSqlOperation {
    public E3ListarEnfermedadesRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"listarEnfermedades","prod.PA_E3_Enfermedad_Sel_Listado");
    }
}
