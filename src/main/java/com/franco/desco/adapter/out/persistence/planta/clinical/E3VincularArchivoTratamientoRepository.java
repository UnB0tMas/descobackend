package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: vincular un archivo local a una aplicación de tratamiento. */
@Repository
public final class E3VincularArchivoTratamientoRepository extends E3ClinicalSqlOperation {
    public E3VincularArchivoTratamientoRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"vincularArchivoTratamiento","sanidad.PA_E3_TratamientoArchivo_Ins_Vinculo");
    }
}
