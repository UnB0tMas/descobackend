package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * APAPPSS no es una funcionalidad genérica para todas las asociaciones.
 * Se reutiliza la asociación existente por RUC; nunca se inventa un convenio.
 */
@Component
@Order(10)
public class ApappssModuleBootstrap implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(ApappssModuleBootstrap.class);
    private static final String RUC_APAPPSS = "20602771394";
    private final JdbcTemplate jdbc;

    public ApappssModuleBootstrap(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Integer asociaciones = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM org.Empresa E
                INNER JOIN org.Asociacion A ON A.asociacion_id = E.empresa_id
                WHERE E.ruc = ? AND E.estado = 1 AND A.estado = 1
                """, Integer.class, RUC_APAPPSS);
        if (asociaciones == null || asociaciones != 1) {
            log.warn("[APAPPSS] Asociación activa no identificada de forma única por RUC; no se asignaron convenios.");
            return;
        }

        // No habilitar APAPPSS para otra empresa por el solo hecho de tener convenio.
        int revocados = jdbc.update("""
                UPDATE CM SET estado = 0, fecha_modificacion = SYSUTCDATETIME()
                FROM org.ConvenioModuloEspecial CM
                INNER JOIN org.ConvenioUOTOrganizacion CU
                    ON CU.convenio_uot_organizacion_id = CM.convenio_uot_organizacion_id
                INNER JOIN org.Empresa E ON E.empresa_id = CU.empresa_id
                INNER JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id = CM.modulo_especial_id
                WHERE ME.codigo = 'COMERCIALIZACION_ASOCIATIVA'
                    AND E.ruc <> ? AND CM.estado = 1
                """, RUC_APAPPSS);

        // Incorporar únicamente vínculos territoriales preexistentes, activos y válidos.
        // Una deshabilitación expresa (fila existente con estado=0) se respeta.
        int nuevos = jdbc.update("""
                INSERT INTO org.ConvenioModuloEspecial
                    (convenio_uot_organizacion_id, modulo_especial_id, estado, fecha_modificacion)
                SELECT CU.convenio_uot_organizacion_id, ME.modulo_especial_id, 1, SYSUTCDATETIME()
                FROM org.ConvenioUOTOrganizacion CU
                INNER JOIN org.Empresa E ON E.empresa_id = CU.empresa_id
                INNER JOIN org.Asociacion A ON A.asociacion_id = E.empresa_id AND A.estado = 1
                INNER JOIN org.UOT U ON U.uot_id = CU.uot_id AND U.estado = 1 AND U.es_raiz = 0
                CROSS JOIN seg.ModuloEspecial ME
                WHERE E.ruc = ? AND E.estado = 1 AND CU.estado = 1
                  AND CU.tipo_vinculo = 'ASOCIACION'
                  AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio <= CONVERT(date, SYSUTCDATETIME()))
                  AND (CU.fecha_fin IS NULL OR CU.fecha_fin >= CONVERT(date, SYSUTCDATETIME()))
                  AND ME.codigo = 'COMERCIALIZACION_ASOCIATIVA' AND ME.estado = 1
                  AND NOT EXISTS (SELECT 1 FROM org.ConvenioModuloEspecial CM WITH (UPDLOCK, HOLDLOCK)
                      WHERE CM.convenio_uot_organizacion_id = CU.convenio_uot_organizacion_id
                        AND CM.modulo_especial_id = ME.modulo_especial_id)
                """, RUC_APAPPSS);
        log.info("[APAPPSS] Módulos de convenios ajenos revocados={}, vínculos existentes habilitados={}", revocados, nuevos);
    }
}
