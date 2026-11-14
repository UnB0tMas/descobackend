package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: actualizar un tratamiento existente y auditar su edición. */
@Repository
public final class E3EditarTratamientoRepository extends E3ClinicalSqlOperation {
    public E3EditarTratamientoRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"editarTratamiento","prod.PA_E3_Tratamiento_Upd_Registro");
    }
}
