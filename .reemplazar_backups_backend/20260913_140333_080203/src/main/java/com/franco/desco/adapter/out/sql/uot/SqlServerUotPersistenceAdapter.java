package com.franco.desco.adapter.out.sql.uot;

import com.franco.desco.adapter.out.sql.common.SqlIdempotencyCoordinator;
import com.franco.desco.adapter.out.sql.common.SqlProcedureExecutor;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.UotCommands;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import com.franco.desco.domain.uot.UotModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.time.LocalDate;
import java.util.*;

@Repository
public class SqlServerUotPersistenceAdapter implements UotPersistencePort {
    private final JdbcTemplate jdbc;
    private final SqlProcedureExecutor procedures;
    private final SqlIdempotencyCoordinator idempotency;

    public SqlServerUotPersistenceAdapter(JdbcTemplate jdbc, SqlProcedureExecutor procedures, SqlIdempotencyCoordinator idempotency) {
        this.jdbc = jdbc;
        this.procedures = procedures;
        this.idempotency = idempotency;
    }

    @Override
    public PersistenceResult<UotModels.Context> context(SessionIdentity identity) {
        try {
            List<UotModels.Membership> memberships = memberships(identity.usuarioId());
            SessionRow session = session(identity);
            String mode = session == null || session.mode() == null ? "ESPECIFICA" : session.mode();
            Long selected = session == null ? null : session.uotId();

            if ("ESPECIFICA".equals(mode) && selected == null && memberships.size() == 1) {
                selected = memberships.getFirst().uotId();
            }
            if (selected != null) {
                Long selectedCandidate = selected;
                if (memberships.stream().noneMatch(item -> Objects.equals(item.uotId(), selectedCandidate))) {
                    selected = null;
                }
            }

            boolean generalAllowed = memberships.stream().anyMatch(item -> rawPermission(identity.usuarioId(), item.uotId(), "UOT_MODO_GENERAL"));
            boolean selectionRequired = "ESPECIFICA".equals(mode) && selected == null && memberships.size() > 1;
            return PersistenceResult.ok("Contexto de UOT obtenido correctamente.",
                    new UotModels.Context(mode, selected, selectionRequired, generalAllowed, memberships));
        } catch (DataAccessException exception) {
            return PersistenceResult.error("UOT_CONTEXTO_NO_DISPONIBLE", "No se pudo obtener el contexto de trabajo.", 503);
        }
    }

    @Override
    public PersistenceResult<Void> select(UotCommands.SelectContext command, SessionIdentity identity) {
        if (command == null || command.mode() == null) return PersistenceResult.error("El modo de trabajo es obligatorio.");
        SessionRow session = session(identity);
        if (session == null) return PersistenceResult.error("La sesión ya no está disponible.");

        Map<String, Object> in = map(
                "nUsuarioId", identity.usuarioId(),
                "nSesionUsuarioId", session.id(),
                "cModo", command.mode().trim().toUpperCase(Locale.ROOT),
                "nUotId", command.uotId()
        );
        Map<String, Object> out = procedures.call("seg", "PA_Sesion_Upd_ContextoUOT", in,
                new SqlParameter("nUsuarioId", Types.BIGINT),
                new SqlParameter("nSesionUsuarioId", Types.BIGINT),
                new SqlParameter("cModo", Types.VARCHAR),
                new SqlParameter("nUotId", Types.BIGINT),
                new SqlOutParameter("bResultado", Types.BIT),
                new SqlOutParameter("cMensaje", Types.NVARCHAR));
        return voidResult(out, "No se pudo cambiar el contexto de trabajo.");
    }

    @Override
    public PersistenceResult<List<UotModels.Unit>> list(SessionIdentity identity, Long uotId, boolean includeInactive) {
        try {
            if (uotId != null && !hasAccess(identity, uotId)) return PersistenceResult.error("No tiene acceso a la UOT seleccionada.");
            List<UotModels.Unit> values = jdbc.query("""
                    SELECT U.uot_id,U.uot_padre_id,U.ubicacion_id,U.codigo,U.nombre,U.descripcion,U.es_raiz,
                           U.fecha_inicio,U.fecha_fin,U.estado,CAST(1 AS bit) asignada,UU.es_predeterminada
                    FROM seg.UsuarioUOT UU
                    JOIN org.UOT U ON U.uot_id=UU.uot_id
                    WHERE UU.usuario_id=? AND UU.estado=1 AND UU.fecha_hasta IS NULL
                      AND (?=1 OR U.estado=1) AND (? IS NULL OR U.uot_id=?)
                    ORDER BY U.es_raiz DESC,U.nombre
                    """, (rs, rowNum) -> new UotModels.Unit(
                            rs.getLong("uot_id"), nullableLong(rs, "uot_padre_id"), nullableLong(rs, "ubicacion_id"),
                            rs.getString("codigo"), rs.getString("nombre"), rs.getString("descripcion"), rs.getBoolean("es_raiz"),
                            localDate(rs, "fecha_inicio"), localDate(rs, "fecha_fin"), rs.getBoolean("estado"), true, rs.getBoolean("es_predeterminada")),
                    identity.usuarioId(), includeInactive, uotId, uotId);
            return PersistenceResult.ok("UOT consultadas correctamente.", values);
        } catch (DataAccessException exception) {
            return PersistenceResult.error("UOT_NO_LISTADAS", "No se pudieron consultar las UOT.", 503);
        }
    }

    @Override
    public PersistenceResult<Long> create(UotCommands.CreateUnit command, SessionIdentity identity) {
        return idempotency.executeLong(identity.usuarioId(), command.idempotencyKey(), "UOT_CREAR", "org", "UOT", () -> {
            Map<String, Object> out = procedures.call("org", "PA_UOT_Ins_Registro", map(
                            "nUsuarioId", identity.usuarioId(), "nUotPadreId", command.parentUotId(), "nUbicacionId", command.locationId(),
                            "cCodigo", command.code(), "cNombre", command.name(), "cDescripcion", command.description()),
                    new SqlParameter("nUsuarioId", Types.BIGINT), new SqlParameter("nUotPadreId", Types.BIGINT),
                    new SqlParameter("nUbicacionId", Types.BIGINT), new SqlParameter("cCodigo", Types.VARCHAR),
                    new SqlParameter("cNombre", Types.NVARCHAR), new SqlParameter("cDescripcion", Types.NVARCHAR),
                    new SqlOutParameter("nUotId", Types.BIGINT), new SqlOutParameter("bResultado", Types.BIT),
                    new SqlOutParameter("cMensaje", Types.NVARCHAR));
            if (!SqlProcedureExecutor.success(out)) return PersistenceResult.error(SqlProcedureExecutor.message(out, "No se pudo registrar la UOT."));
            return PersistenceResult.ok("UOT registrada correctamente.", SqlProcedureExecutor.longValue(out, "nUotId"));
        });
    }

    @Override
    public PersistenceResult<Void> update(UotCommands.UpdateUnit command, SessionIdentity identity) {
        Map<String, Object> out = procedures.call("org", "PA_UOT_Upd_Registro", map(
                        "nUsuarioId", identity.usuarioId(), "nUotId", command.uotId(), "nUotPadreId", command.parentUotId(),
                        "nUbicacionId", command.locationId(), "cNombre", command.name(), "cDescripcion", command.description(), "bEstado", command.active()),
                new SqlParameter("nUsuarioId", Types.BIGINT), new SqlParameter("nUotId", Types.BIGINT),
                new SqlParameter("nUotPadreId", Types.BIGINT), new SqlParameter("nUbicacionId", Types.BIGINT),
                new SqlParameter("cNombre", Types.NVARCHAR), new SqlParameter("cDescripcion", Types.NVARCHAR), new SqlParameter("bEstado", Types.BIT),
                new SqlOutParameter("bResultado", Types.BIT), new SqlOutParameter("cMensaje", Types.NVARCHAR));
        return voidResult(out, "No se pudo actualizar la UOT.");
    }

    @Override
    public PersistenceResult<Void> assignUser(UotCommands.AssignUser command, SessionIdentity identity) {
        Map<String, Object> out = procedures.call("seg", "PA_UsuarioUOT_Ins_Asignar", map(
                        "nActorUsuarioId", identity.usuarioId(), "nUsuarioId", command.userId(), "nUotId", command.uotId(), "bPredeterminada", command.defaultUnit()),
                new SqlParameter("nActorUsuarioId", Types.BIGINT), new SqlParameter("nUsuarioId", Types.BIGINT),
                new SqlParameter("nUotId", Types.BIGINT), new SqlParameter("bPredeterminada", Types.BIT),
                new SqlOutParameter("bResultado", Types.BIT), new SqlOutParameter("cMensaje", Types.NVARCHAR));
        return voidResult(out, "No se pudo asignar la UOT.");
    }

    @Override
    public PersistenceResult<Void> assignRole(UotCommands.AssignRole command, SessionIdentity identity) {
        Map<String, Object> out = procedures.call("seg", "PA_UsuarioUOTRol_Ins_Asignar", map(
                        "nActorUsuarioId", identity.usuarioId(), "nUsuarioId", command.userId(), "nUotId", command.uotId(), "nRolId", command.roleId()),
                new SqlParameter("nActorUsuarioId", Types.BIGINT), new SqlParameter("nUsuarioId", Types.BIGINT),
                new SqlParameter("nUotId", Types.BIGINT), new SqlParameter("nRolId", Types.BIGINT),
                new SqlOutParameter("bResultado", Types.BIT), new SqlOutParameter("cMensaje", Types.NVARCHAR));
        return voidResult(out, "No se pudo asignar el rol.");
    }

    @Override
    public boolean hasPermission(SessionIdentity identity, String permissionCode) {
        if (identity == null) return false;
        List<UotModels.Membership> values = memberships(identity.usuarioId());
        if (values.isEmpty()) return false;
        SessionRow session = session(identity);
        String mode = session == null || session.mode() == null ? "ESPECIFICA" : session.mode();
        if ("GENERAL".equals(mode)) {
            return values.stream().anyMatch(item -> rawPermission(identity.usuarioId(), item.uotId(), permissionCode));
        }
        Long selected = session == null ? null : session.uotId();
        if (selected == null && values.size() == 1) selected = values.getFirst().uotId();
        return selected != null && rawPermission(identity.usuarioId(), selected, permissionCode);
    }

    @Override
    public boolean hasPermission(SessionIdentity identity, Long uotId, String permissionCode) {
        if (!inCurrentScope(identity, uotId)) return false;
        return rawPermission(identity.usuarioId(), uotId, permissionCode);
    }

    @Override
    public boolean hasAccess(SessionIdentity identity, Long uotId) {
        return inCurrentScope(identity, uotId) && rawAccess(identity.usuarioId(), uotId);
    }

    private boolean inCurrentScope(SessionIdentity identity, Long requested) {
        if (identity == null || requested == null || !rawAccess(identity.usuarioId(), requested)) return false;
        SessionRow session = session(identity);
        String mode = session == null || session.mode() == null ? "ESPECIFICA" : session.mode();
        if ("GENERAL".equals(mode)) return true;
        Long selected = session == null ? null : session.uotId();
        if (selected == null) {
            List<UotModels.Membership> values = memberships(identity.usuarioId());
            if (values.size() == 1) selected = values.getFirst().uotId();
        }
        return Objects.equals(selected, requested);
    }

    private boolean rawPermission(Long userId, Long uotId, String permissionCode) {
        Integer value = jdbc.queryForObject("SELECT CONVERT(int,seg.FN_Usuario_TienePermisoUOT(?,?,?))", Integer.class, userId, uotId, permissionCode);
        return value != null && value == 1;
    }

    private boolean rawAccess(Long userId, Long uotId) {
        Integer value = jdbc.queryForObject("SELECT CONVERT(int,seg.FN_Usuario_TieneAccesoUOT(?,?))", Integer.class, userId, uotId);
        return value != null && value == 1;
    }

    private List<UotModels.Membership> memberships(Long userId) {
        return jdbc.query("""
                SELECT UU.usuario_uot_id,UU.uot_id,U.codigo,U.nombre,UU.es_predeterminada,
                       STRING_AGG(R.codigo,',') WITHIN GROUP(ORDER BY R.codigo) roles
                FROM seg.UsuarioUOT UU
                JOIN org.UOT U ON U.uot_id=UU.uot_id AND U.estado=1
                LEFT JOIN seg.UsuarioUOTRol UR ON UR.usuario_uot_id=UU.usuario_uot_id AND UR.estado=1 AND UR.fecha_hasta IS NULL
                LEFT JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
                WHERE UU.usuario_id=? AND UU.estado=1 AND UU.fecha_hasta IS NULL
                GROUP BY UU.usuario_uot_id,UU.uot_id,U.codigo,U.nombre,UU.es_predeterminada
                ORDER BY UU.es_predeterminada DESC,U.nombre
                """, (rs, rowNum) -> new UotModels.Membership(rs.getLong("usuario_uot_id"), rs.getLong("uot_id"),
                rs.getString("codigo"), rs.getString("nombre"), rs.getBoolean("es_predeterminada"), splitRoles(rs.getString("roles"))), userId);
    }

    private SessionRow session(SessionIdentity identity) {
        List<SessionRow> rows = jdbc.query("""
                SELECT TOP(1) sesion_usuario_id,modo_uot,uot_contexto_id
                FROM seg.SesionUsuario
                WHERE sesion_publica_id=? AND usuario_id=? AND estado=1 AND fecha_revocacion IS NULL
                """, (rs, rowNum) -> new SessionRow(rs.getLong("sesion_usuario_id"), rs.getString("modo_uot"), nullableLong(rs, "uot_contexto_id")),
                identity.sesionPublicaId(), identity.usuarioId());
        return rows.isEmpty() ? null : rows.getFirst();
    }

    private static List<String> splitRoles(String value) {
        if (value == null || value.isBlank()) return List.of();
        return Arrays.stream(value.split(",")).map(String::trim).filter(v -> !v.isBlank()).distinct().toList();
    }

    private static Long nullableLong(java.sql.ResultSet rs, String name) throws java.sql.SQLException {
        long value = rs.getLong(name);
        return rs.wasNull() ? null : value;
    }

    private static LocalDate localDate(java.sql.ResultSet rs, String name) throws java.sql.SQLException {
        java.sql.Date value = rs.getDate(name);
        return value == null ? null : value.toLocalDate();
    }

    private static Map<String, Object> map(Object... pairs) {
        Map<String, Object> values = new LinkedHashMap<>();
        for (int i = 0; i < pairs.length; i += 2) values.put(String.valueOf(pairs[i]), pairs[i + 1]);
        return values;
    }

    private static PersistenceResult<Void> voidResult(Map<String, Object> out, String fallback) {
        if (!SqlProcedureExecutor.success(out)) return PersistenceResult.error(SqlProcedureExecutor.message(out, fallback));
        return PersistenceResult.ok(SqlProcedureExecutor.message(out, "Acción realizada."), null);
    }

    private record SessionRow(Long id, String mode, Long uotId) {}
}
