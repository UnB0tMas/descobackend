package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Tratamiento_Sel_Listado. */
@Repository
public final class E3ListarTratamientosRepository extends E3ClinicalSqlOperation {
    public E3ListarTratamientosRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"listarTratamientos","prod.PA_E3_Tratamiento_Sel_Listado");
    }
}
