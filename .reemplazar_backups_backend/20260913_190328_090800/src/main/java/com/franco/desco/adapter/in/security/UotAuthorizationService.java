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
                """,
                Integer.class, identity.usuarioId(), identity.usuarioId(), permission
        );
        return count != null && count > 0;
    }

    public boolean hasPermission(SessionIdentity identity, Long uotId, String permissionCode) {
        if (identity == null || uotId == null || permissionCode == null || permissionCode.isBlank()) return false;
        Integer value = jdbc.queryForObject(
                "SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                Integer.class, identity.usuarioId(), uotId, permissionCode.trim().toUpperCase()
        );
        return value != null && value == 1;
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
