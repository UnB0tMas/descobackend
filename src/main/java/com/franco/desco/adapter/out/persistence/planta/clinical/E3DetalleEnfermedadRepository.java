package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Enfermedad_Sel_Detalle. */
@Repository
public final class E3DetalleEnfermedadRepository extends E3ClinicalSqlOperation {
    public E3DetalleEnfermedadRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"detalleEnfermedad","prod.PA_E3_Enfermedad_Sel_Detalle");
    }
}
