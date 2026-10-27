package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sincroniza los permisos del rol administrador de sistema al iniciar DESCO.
 * La autorización por UOT y los módulos de convenios inactivos se siguen
 * validando en seg.FN_Usuario_TienePermisoUOT.
 */
@Component
public class AdministratorAccessBootstrap implements ApplicationRunner {

    private static final Logger log =
            LoggerFactory.getLogger(AdministratorAccessBootstrap.class);

    private static final String ADMIN_ROLE = "ADMINISTRADOR";

    private final JdbcTemplate jdbc;

    public AdministratorAccessBootstrap(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Integer roles = jdbc.queryForObject(
                "SELECT COUNT(*) FROM [seg].[Rol] WHERE [codigo]=? AND [estado]=1",
                Integer.class,
                ADMIN_ROLE
        );
        if (roles == null || roles != 1) {
            throw new IllegalStateException(
                    "No existe un unico rol ADMINISTRADOR activo en seg.Rol."
            );
        }

        // Restaurar permisos del rol que ya existan pero esten inactivos.
        int restored = jdbc.update(
                """
                UPDATE RP
                   SET RP.estado=1,
                       RP.fecha_retiro=NULL,
                       RP.retirado_por_usuario_id=NULL,
                       RP.motivo_retiro=NULL
                FROM [seg].[RolPermiso] RP
                JOIN [seg].[Rol] R ON R.rol_id=RP.rol_id
                JOIN [seg].[Permiso] P ON P.permiso_id=RP.permiso_id
                WHERE R.codigo=? AND R.estado=1
                  AND P.estado=1 AND RP.estado=0
                """,
                ADMIN_ROLE
        );

        // Incluir permisos creados por nuevos modulos, sin registros duplicados.
        int created = jdbc.update(
                """
                INSERT INTO [seg].[RolPermiso]
                    ([rol_id], [permiso_id], [estado], [fecha_asignacion])
                SELECT R.rol_id, P.permiso_id, 1, SYSUTCDATETIME()
                FROM [seg].[Rol] R
                CROSS JOIN [seg].[Permiso] P
                WHERE R.codigo=? AND R.estado=1 AND P.estado=1
                  AND NOT EXISTS (
                      SELECT 1
                      FROM [seg].[RolPermiso] RP WITH (UPDLOCK, HOLDLOCK)
                      WHERE RP.rol_id=R.rol_id AND RP.permiso_id=P.permiso_id
                  )
                """,
                ADMIN_ROLE
        );

        log.info(
                "[BOOTSTRAP] Rol ADMINISTRADOR sincronizado: nuevos={}, reactivados={}",
                created,
                restored
        );
    }
}
