package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

/** DEV: establecer Sara Sara como unidad principal del administrador, sin revocar accesos. */
@Component
@Order(25)
public class CorrespondenceAdminUotBootstrap implements ApplicationRunner {
    private static final Logger LOG = LoggerFactory.getLogger(CorrespondenceAdminUotBootstrap.class);
    private final JdbcTemplate jdbc;

    public CorrespondenceAdminUotBootstrap(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        List<long[]> administrators = jdbc.query("""
            SELECT U.usuario_id, E.empleado_id, T.uot_id
            FROM seg.Usuario U
            JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
            JOIN org.UOT T ON T.codigo='UOT_LEGACY_4' AND T.estado=1
            WHERE U.nombre_usuario='admin' AND U.estado=1 AND U.estado_cuenta='ACTIVA'
              AND EXISTS (
                  SELECT 1 FROM seg.UsuarioRol UR
                  JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
                  WHERE UR.usuario_id=U.usuario_id AND UR.estado=1
                    AND R.codigo='ADMINISTRADOR'
                    AND UR.fecha_desde<=SYSUTCDATETIME()
                    AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
              )
            """, (rs, row) -> new long[] {
                rs.getLong("usuario_id"), rs.getLong("empleado_id"), rs.getLong("uot_id")
            });

        if (administrators.isEmpty()) {
            LOG.warn("[BOOTSTRAP] Administrador activo o UOT Sara Sara no disponible.");
            return;
        }
        if (administrators.size()!=1) {
            throw new IllegalStateException("Configuración ambigua del administrador/UOT Sara Sara.");
        }

        long[] admin=administrators.getFirst();
        long usuarioId=admin[0], empleadoId=admin[1], saraSaraId=admin[2];

        // Primero retirar la principal anterior: los índices filtrados impiden dos principales.
        jdbc.update("""
            UPDATE org.EmpleadoUOT SET es_principal=0
            WHERE empleado_id=? AND uot_id<>? AND estado=1
              AND fecha_hasta IS NULL AND es_principal=1
            """, empleadoId, saraSaraId);

        int vinculo=jdbc.update("""
            UPDATE org.EmpleadoUOT SET es_principal=1
            WHERE empleado_id=? AND uot_id=? AND estado=1
              AND fecha_hasta IS NULL AND es_principal=0
            """, empleadoId, saraSaraId);
        if (vinculo==0) {
            jdbc.update("""
                IF NOT EXISTS (
                    SELECT 1 FROM org.EmpleadoUOT WITH (UPDLOCK,HOLDLOCK)
                    WHERE empleado_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL
                )
                BEGIN
                    INSERT INTO org.EmpleadoUOT
                        (empleado_id,uot_id,es_principal,fecha_desde,estado)
                    VALUES (?,?,1,CONVERT(date,SYSUTCDATETIME()),1);
                END;
                """, empleadoId, saraSaraId, empleadoId, saraSaraId);
        }

        jdbc.update("""
            UPDATE seg.UsuarioUOT SET es_predeterminada=0
            WHERE usuario_id=? AND uot_id<>? AND estado=1
              AND fecha_hasta IS NULL AND es_predeterminada=1
            """, usuarioId, saraSaraId);
        int acceso=jdbc.update("""
            UPDATE seg.UsuarioUOT SET es_predeterminada=1
            WHERE usuario_id=? AND uot_id=? AND estado=1
              AND fecha_hasta IS NULL AND es_predeterminada=0
            """, usuarioId, saraSaraId);
        if (acceso==0) {
            jdbc.update("""
                IF NOT EXISTS (
                    SELECT 1 FROM seg.UsuarioUOT WITH (UPDLOCK,HOLDLOCK)
                    WHERE usuario_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL
                )
                BEGIN
                    INSERT INTO seg.UsuarioUOT
                        (usuario_id,uot_id,es_predeterminada,fecha_desde,estado)
                    VALUES (?,?,1,SYSUTCDATETIME(),1);
                END;
                """, usuarioId, saraSaraId, usuarioId, saraSaraId);
        }
        LOG.info("[BOOTSTRAP] Administrador: UOT principal y predeterminada Sara Sara; acceso a General conservado.");
    }
}

