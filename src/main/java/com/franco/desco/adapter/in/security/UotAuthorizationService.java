package com.franco.desco.adapter.in.security;

import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class UotAuthorizationService {
    private final JdbcTemplate jdbc;

    public UotAuthorizationService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public boolean hasCurrentPermission(SessionIdentity identity, String permissionCode) {
        if (identity == null || permissionCode == null || permissionCode.isBlank()) return false;
        String permission = permissionCode.trim().toUpperCase();
        var rows = jdbc.query(
                """
                SELECT TOP(1) modo_uot, uot_contexto_id
                FROM seg.SesionUsuario
                WHERE sesion_publica_id=? AND usuario_id=? AND estado=1 AND fecha_revocacion IS NULL
                """,
                (rs, rowNum) -> new SessionUot(rs.getString("modo_uot"), (Long) rs.getObject("uot_contexto_id")),
                identity.sesionPublicaId(), identity.usuarioId()
        );
        if (rows.isEmpty()) return false;
        SessionUot context = rows.getFirst();
        if ("ESPECIFICA".equalsIgnoreCase(context.mode())) {
            return context.uotId() != null && hasPermission(identity, context.uotId(), permission);
        }
        Integer count = jdbc.queryForObject(
                """
                SELECT COUNT(*)
                FROM seg.UsuarioUOT UU
                JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1
                WHERE UU.usuario_id=? AND UU.estado=1 AND UU.fecha_hasta IS NULL
                  AND seg.FN_Usuario_TienePermisoUOT(?,UU.uot_id,?)=1
                  AND NOT EXISTS (
                      SELECT 1 FROM seg.ModuloEspecialPermiso MP
                      JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id
                      WHERE P.codigo=? AND P.estado=1
                  )
                """,
                Integer.class, identity.usuarioId(), identity.usuarioId(), permission, permission
        );
        return count != null && count > 0;
    }

    public boolean hasPermission(SessionIdentity identity, Long uotId, String permissionCode) {
        if (identity == null || uotId == null || permissionCode == null || permissionCode.isBlank()) return false;
        Integer value = jdbc.queryForObject(
                "SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                Integer.class, identity.usuarioId(), uotId, permissionCode.trim().toUpperCase()
        );
        if (value == null || value != 1) return false;
        Integer enabled = jdbc.queryForObject(
                """
                SELECT CASE
                    WHEN NOT EXISTS (
                        SELECT 1 FROM seg.ModuloEspecialPermiso MP
                        JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id
                        WHERE P.codigo=? AND P.estado=1
                    ) THEN 1
                    WHEN EXISTS (
                        SELECT 1 FROM seg.ModuloEspecialPermiso MP
                        JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id AND P.codigo=? AND P.estado=1
                        JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id AND M.estado=1
                        JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id=M.modulo_especial_id AND CM.estado=1
                        JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=CM.convenio_uot_organizacion_id
                        JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                        WHERE C.uot_id=? AND C.estado=1
                          AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                          AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                    ) THEN 1 ELSE 0 END
                """,
                Integer.class, permissionCode.trim().toUpperCase(), permissionCode.trim().toUpperCase(), uotId
        );
        return enabled != null && enabled == 1;
    }

    public boolean hasAccess(SessionIdentity identity, Long uotId) {
        if (identity == null || uotId == null) return false;
        Integer value = jdbc.queryForObject(
                "SELECT CONVERT(INT,seg.FN_Usuario_TieneAccesoUOT(?,?))",
                Integer.class, identity.usuarioId(), uotId
        );
        return value != null && value == 1;
    }

    private record SessionUot(String mode, Long uotId) {}
}
