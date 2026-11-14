package com.franco.desco.adapter.out.persistence.planta.clinical;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

/** Responsabilidad única: PA_E3_Comentario_Ins_Registro. */
@Repository
public final class E3RegistrarComentarioRepository extends E3ClinicalSqlOperation {
    public E3RegistrarComentarioRepository(JdbcTemplate jdbc,JsonMapper json) {
        super(jdbc,json,"registrarComentario","prod.PA_E3_Comentario_Ins_Registro");
    }
}
