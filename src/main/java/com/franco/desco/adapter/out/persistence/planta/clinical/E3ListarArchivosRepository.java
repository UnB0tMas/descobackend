package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: listar archivos generales y de tratamientos de la planta. */
@Repository
public final class E3ListarArchivosRepository extends E3ClinicalSqlOperation {
    public E3ListarArchivosRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"listarArchivos","prod.PA_E3_Archivo_Sel_Listado");
    }
}
