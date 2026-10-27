package com.franco.desco.adapter.in.web.convenio;

import com.franco.desco.adapter.in.security.UotAuthorizationService;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Set;
import java.util.HashSet;

@Service
public class ConvenioService {
    private final JdbcTemplate jdbc;
    private final UotAuthorizationService authorization;

    public ConvenioService(JdbcTemplate jdbc, UotAuthorizationService authorization) {
        this.jdbc = jdbc;
        this.authorization = authorization;
    }

    public Long selectedUot(SessionIdentity identity) {
        List<Long> ids = jdbc.query(
                """
                SELECT S.uot_contexto_id FROM seg.SesionUsuario S
                JOIN org.UOT U ON U.uot_id=S.uot_contexto_id AND U.estado=1
                WHERE S.sesion_publica_id=? AND S.usuario_id=?
                  AND S.estado=1 AND S.fecha_revocacion IS NULL
                  AND S.fecha_expiracion_renovacion>SYSUTCDATETIME()
                  AND S.modo_uot='ESPECIFICA'
                """, (rs, index) -> rs.getLong(1), identity.sesionPublicaId(), identity.usuarioId());
        return ids.isEmpty() ? null : ids.getFirst();
    }

    public AppResult<List<ConvenioModuloResponse>> activeModules(SessionIdentity identity) {
        Long uotId = selectedUot(identity);
        if (uotId == null) return AppResult.ok("MODULOS_CONVENIO", "Sin modulos especiales en el contexto.", List.of());
        return AppResult.ok("MODULOS_CONVENIO", "Modulos disponibles.", jdbc.query(
                """
                SELECT DISTINCT M.codigo, M.nombre FROM seg.ModuloEspecial M
                JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id=M.modulo_especial_id AND CM.estado=1
                JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=CM.convenio_uot_organizacion_id
                JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                WHERE C.uot_id=? AND C.estado=1 AND M.estado=1
                  AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                  AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                  AND EXISTS (
                      SELECT 1 FROM seg.ModuloEspecialPermiso MP
                      JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id AND P.estado=1
                      WHERE MP.modulo_especial_id=M.modulo_especial_id
                        AND seg.FN_Usuario_TienePermisoUOT(?,C.uot_id,P.codigo)=1
                  )
                ORDER BY M.nombre
                """, (rs, index) -> new ConvenioModuloResponse(rs.getString(1), rs.getString(2), true), uotId, identity.usuarioId()));
    }

    public AppResult<List<ConvenioDetalleResponse>> list(SessionIdentity identity) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "ORGANIZACIONES_LISTAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "UOT_NO_AUTORIZADA", "Seleccione una UOT autorizada.");
        List<ConvenioDetalleResponse> agreements = jdbc.query(
                """
                SELECT C.convenio_uot_organizacion_id, C.uot_id, C.empresa_id,
                       E.razon_social, C.tipo_vinculo, C.numero_convenio
                FROM org.ConvenioUOTOrganizacion C
                JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                WHERE C.uot_id=? AND C.estado=1
                  AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                  AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                ORDER BY E.razon_social, C.convenio_uot_organizacion_id
                """, (rs, row) -> new ConvenioDetalleResponse(
                        rs.getLong(1), rs.getLong(2), rs.getLong(3), rs.getString(4),
                        rs.getString(5), rs.getString(6), List.of()), uotId);
        List<ConvenioDetalleResponse> output = agreements.stream().map(c ->
                new ConvenioDetalleResponse(c.convenioId(), c.uotId(), c.organizacionId(),
                        c.organizacion(), c.tipoVinculo(), c.numeroConvenio(), jdbc.query(
                        """
                        SELECT M.codigo, M.nombre, CAST(ISNULL(CM.estado, 0) AS bit)
                        FROM seg.ModuloEspecial M
                        LEFT JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id=M.modulo_especial_id
                          AND CM.convenio_uot_organizacion_id=?
                        WHERE M.estado=1 ORDER BY M.nombre
                        """, (rs, index) -> new ConvenioModuloResponse(
                                rs.getString(1), rs.getString(2), rs.getBoolean(3)), c.convenioId()))
        ).toList();
        return AppResult.ok("CONVENIOS_LISTADOS", "Convenios de la UOT.", output);
    }

    @Transactional
    public AppResult<Void> configure(SessionIdentity identity, Long convenioId, String codigo, boolean habilitado) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "ORGANIZACIONES_EDITAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "UOT_NO_AUTORIZADA", "No puede gestionar convenios en esta UOT.");
        List<Integer> moduleIds = jdbc.query(
                "SELECT modulo_especial_id FROM seg.ModuloEspecial WHERE codigo=? AND estado=1",
                (rs, index) -> rs.getInt(1), codigo);
        if (moduleIds.isEmpty())
            return AppResult.error(AppStatus.BAD_REQUEST, "MODULO_INVALIDO", "El modulo especial no existe.");
        List<Long> found = jdbc.query(
                """
                SELECT C.convenio_uot_organizacion_id
                FROM org.ConvenioUOTOrganizacion C
                JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                WHERE C.convenio_uot_organizacion_id=? AND C.uot_id=? AND C.estado=1
                  AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                  AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                """, (rs, index) -> rs.getLong(1), convenioId, uotId);
        if (found.isEmpty())
            return AppResult.error(AppStatus.NOT_FOUND, "CONVENIO_NO_DISPONIBLE", "Convenio no disponible en la UOT seleccionada.");
        int changed = jdbc.update(
                """
                UPDATE org.ConvenioModuloEspecial WITH (UPDLOCK, HOLDLOCK)
                SET estado=?, fecha_modificacion=SYSUTCDATETIME(), usuario_modificacion_id=?
                WHERE convenio_uot_organizacion_id=? AND modulo_especial_id=?
                """, habilitado, identity.usuarioId(), convenioId, moduleIds.getFirst());
        if (changed == 0) {
            jdbc.update(
                    """
                    INSERT INTO org.ConvenioModuloEspecial
                        (convenio_uot_organizacion_id, modulo_especial_id, estado, usuario_modificacion_id)
                    VALUES (?, ?, ?, ?)
                    """, convenioId, moduleIds.getFirst(), habilitado, identity.usuarioId());
        }
        jdbc.update(
                """
                INSERT INTO auditoria.AuditoriaEvento
                    (usuario_id, accion, esquema_entidad, nombre_entidad, identificador,
                     datos_posteriores, motivo, resultado)
                VALUES (?, ?, 'org', 'ConvenioModuloEspecial', ?, ?, ?, 'EXITOSO')
                """,
                identity.usuarioId(), habilitado ? "HABILITAR" : "DESHABILITAR",
                convenioId + ":" + codigo,
                "{\"habilitado\":" + habilitado + "}",
                "Cambio de habilitacion de modulo especial por convenio y UOT"
        );
        return AppResult.ok("MODULO_CONVENIO_CONFIGURADO", "Configuracion guardada.", null);
    }

    public AppResult<List<ConvenioAsociacionResponse>> activeAssociations(SessionIdentity identity) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "APAPPSS_SOCIOS_LISTAR")
                || !authorization.hasPermission(identity, uotId, "PRODUCTORES_LISTAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "SIN_ACCESO", "No puede consultar socios de APAPPSS.");
        return AppResult.ok("ASOCIACIONES_APAPPSS", "Asociaciones habilitadas en esta UOT.", jdbc.query(
                """
                SELECT DISTINCT E.empresa_id,E.razon_social
                FROM org.ConvenioUOTOrganizacion C
                JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
                JOIN org.ConvenioModuloEspecial CM
                    ON CM.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND CM.estado=1
                JOIN seg.ModuloEspecial M ON M.modulo_especial_id=CM.modulo_especial_id
                    AND M.codigo='COMERCIALIZACION_ASOCIATIVA' AND M.estado=1
                WHERE C.uot_id=? AND C.estado=1
                  AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                  AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                ORDER BY E.razon_social
                """,(rs,i)->new ConvenioAsociacionResponse(rs.getLong(1),rs.getString(2)),uotId));
    }

    public AppResult<List<ConvenioModuloPermisoResponse>> availablePermissions(
            SessionIdentity identity, String code) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "USUARIOS_LISTAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "SIN_ACCESO", "No puede consultar los permisos de la UOT.");
        if (!moduleExists(code))
            return AppResult.error(AppStatus.NOT_FOUND, "MODULO_INVALIDO", "El módulo no existe.");
        return AppResult.ok("PERMISOS_MODULO", "Permisos del módulo.", jdbc.query(
                """
                SELECT P.codigo,P.nombre FROM seg.ModuloEspecialPermiso MP
                JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id
                JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id AND P.estado=1
                WHERE M.codigo=? AND M.estado=1 ORDER BY P.codigo
                """, (rs, i) -> new ConvenioModuloPermisoResponse(rs.getString(1),rs.getString(2)), code));
    }

    public AppResult<List<ConvenioModuloUsuarioResponse>> usersPermissions(
            SessionIdentity identity, String code) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "USUARIOS_LISTAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "SIN_ACCESO", "No puede consultar usuarios de la UOT.");
        if (!moduleExists(code))
            return AppResult.error(AppStatus.NOT_FOUND, "MODULO_INVALIDO", "El módulo no existe.");
        List<ConvenioModuloUsuarioResponse> users = jdbc.query(
                """
                SELECT DISTINCT U.usuario_id,U.nombre_usuario,
                       CONCAT(P.nombres, ' ', P.apellido_paterno, ' ', ISNULL(P.apellido_materno,''))
                FROM seg.UsuarioUOT UU
                JOIN seg.Usuario U ON U.usuario_id=UU.usuario_id AND U.estado=1
                JOIN org.Persona P ON P.persona_id=U.persona_id AND P.estado=1
                JOIN org.Empleado E ON E.empleado_id=P.persona_id AND E.estado=1
                WHERE UU.uot_id=? AND UU.estado=1
                  AND UU.fecha_desde<=SYSUTCDATETIME()
                  AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
                  AND EXISTS (
                      SELECT 1 FROM org.EmpleadoUOT EU
                      WHERE EU.empleado_id=E.empleado_id AND EU.uot_id=UU.uot_id
                        AND EU.estado=1 AND EU.fecha_desde<=CONVERT(date,SYSUTCDATETIME())
                        AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(date,SYSUTCDATETIME()))
                  )
                ORDER BY P.nombres,P.apellido_paterno,U.usuario_id
                """, (rs, i) -> new ConvenioModuloUsuarioResponse(
                        rs.getLong(1),rs.getString(2),rs.getString(3),List.of()),uotId);
        List<ConvenioModuloUsuarioResponse> output = users.stream().map(u ->
                new ConvenioModuloUsuarioResponse(u.usuarioId(),u.usuario(),u.empleado(),jdbc.query(
                        """
                        SELECT DISTINCT P.codigo
                        FROM seg.UsuarioUOT UU
                        JOIN seg.UsuarioUOTPermiso UP ON UP.usuario_uot_id=UU.usuario_uot_id
                            AND UP.permitido=1 AND UP.estado=1
                        JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id AND P.estado=1
                        JOIN seg.ModuloEspecialPermiso MP ON MP.permiso_id=P.permiso_id
                        JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id
                        WHERE UU.usuario_id=? AND UU.uot_id=? AND UU.estado=1 AND M.codigo=?
                          AND UP.usuario_uot_permiso_id=(
                              SELECT MAX(UP2.usuario_uot_permiso_id)
                              FROM seg.UsuarioUOTPermiso UP2
                              WHERE UP2.usuario_uot_id=UU.usuario_uot_id AND UP2.permiso_id=P.permiso_id
                                AND UP2.estado=1
                                AND UP2.fecha_desde<=SYSUTCDATETIME()
                                AND (UP2.fecha_hasta IS NULL OR UP2.fecha_hasta>SYSUTCDATETIME())
                          )
                          AND UU.fecha_desde<=SYSUTCDATETIME()
                          AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
                          AND UP.fecha_desde<=SYSUTCDATETIME()
                          AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta>SYSUTCDATETIME())
                        ORDER BY P.codigo
                        """,(rs,i)->rs.getString(1),u.usuarioId(),uotId,code)))
                .toList();
        return AppResult.ok("USUARIOS_MODULO", "Usuarios y permisos del módulo.",output);
    }

    @Transactional
    public AppResult<Void> updateUserPermissions(SessionIdentity identity, String code,
                                                  Long targetUserId, List<String> permissionCodes) {
        Long uotId = selectedUot(identity);
        if (uotId == null || !authorization.hasPermission(identity, uotId, "USUARIOS_EDITAR"))
            return AppResult.error(AppStatus.FORBIDDEN, "SIN_ACCESO", "No puede asignar permisos de usuarios.");
        if (!moduleEnabled(uotId,code))
            return AppResult.error(AppStatus.FORBIDDEN, "MODULO_INACTIVO", "Primero habilite el módulo para un convenio vigente.");
        if (permissionCodes == null)
            return AppResult.error(AppStatus.BAD_REQUEST, "PERMISOS_INVALIDOS", "Los permisos son obligatorios.");
        Set<String> selected=new HashSet<>();
        for (String permission:permissionCodes) {
            if (permission==null || permission.isBlank())
                return AppResult.error(AppStatus.BAD_REQUEST,"PERMISO_INVALIDO","Código de permiso inválido.");
            selected.add(permission.trim().toUpperCase());
        }
        Set<String> valid=new HashSet<>(jdbc.query(
                """
                SELECT P.codigo FROM seg.ModuloEspecialPermiso MP
                JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id AND M.estado=1
                JOIN seg.Permiso P ON P.permiso_id=MP.permiso_id AND P.estado=1
                WHERE M.codigo=?
                """,(rs,i)->rs.getString(1),code));
        if (!valid.containsAll(selected))
            return AppResult.error(AppStatus.BAD_REQUEST,"PERMISO_INVALIDO","El permiso no corresponde al módulo.");
        List<Long> memberships=jdbc.query(
                """
                SELECT TOP(1) UU.usuario_uot_id FROM seg.UsuarioUOT UU
                JOIN seg.Usuario U ON U.usuario_id=UU.usuario_id AND U.estado=1
                JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
                WHERE UU.usuario_id=? AND UU.uot_id=? AND UU.estado=1
                  AND UU.fecha_desde<=SYSUTCDATETIME()
                  AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
                  AND EXISTS (
                      SELECT 1 FROM org.EmpleadoUOT EU
                      WHERE EU.empleado_id=E.empleado_id AND EU.uot_id=UU.uot_id AND EU.estado=1
                        AND EU.fecha_desde<=CONVERT(date,SYSUTCDATETIME())
                        AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(date,SYSUTCDATETIME()))
                  )
                ORDER BY UU.usuario_uot_id DESC
                """,(rs,i)->rs.getLong(1),targetUserId,uotId);
        if (memberships.isEmpty())
            return AppResult.error(AppStatus.NOT_FOUND,"USUARIO_UOT_INVALIDO","El empleado no pertenece a esta UOT.");
        Long membershipId=memberships.getFirst();

        // Solo se cierran los permisos revocados para evitar modificaciones innecesarias.
        List<String> current=jdbc.query(
                """
                SELECT DISTINCT P.codigo FROM seg.UsuarioUOTPermiso UP
                JOIN seg.ModuloEspecialPermiso MP ON MP.permiso_id=UP.permiso_id
                JOIN seg.ModuloEspecial M ON M.modulo_especial_id=MP.modulo_especial_id
                JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id
                WHERE UP.usuario_uot_id=? AND M.codigo=? AND UP.estado=1 AND UP.permitido=1
                  AND UP.fecha_desde<=SYSUTCDATETIME()
                  AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta>SYSUTCDATETIME())
                """,(rs,i)->rs.getString(1),membershipId,code);
        for (String old : current) {
            if (!selected.contains(old)) {
                jdbc.update(
                        """
                        UPDATE UP SET estado=0,fecha_hasta=SYSUTCDATETIME()
                        FROM seg.UsuarioUOTPermiso UP
                        JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id
                        WHERE UP.usuario_uot_id=? AND P.codigo=? AND UP.estado=1
                        """,membershipId,old);
            }
        }

        // Reemplazar asignaciones anteriores denegadas o caducadas en lugar de generar duplicados.
        for (String permission: selected) {
            List<Long> ids=jdbc.query("SELECT permiso_id FROM seg.Permiso WHERE codigo=? AND estado=1",
                    (rs,i)->rs.getLong(1),permission);
            if (ids.isEmpty()) continue;
            Long permissionId=ids.getFirst();
            Integer assigned=jdbc.queryForObject(
                    """
                    SELECT COUNT(*) FROM seg.UsuarioUOTPermiso
                    WHERE usuario_uot_id=? AND permiso_id=? AND permitido=1 AND estado=1
                      AND fecha_desde<=SYSUTCDATETIME()
                      AND (fecha_hasta IS NULL OR fecha_hasta>SYSUTCDATETIME())
                    """,Integer.class,membershipId,permissionId);
            if (assigned!=null && assigned>0) continue;
            jdbc.update(
                    """
                    UPDATE seg.UsuarioUOTPermiso SET estado=0,fecha_hasta=SYSUTCDATETIME()
                    WHERE usuario_uot_id=? AND permiso_id=? AND estado=1
                    """,membershipId,permissionId);
            jdbc.update(
                    """
                    INSERT INTO seg.UsuarioUOTPermiso
                        (usuario_uot_id,permiso_id,permitido,motivo,asignado_por_usuario_id)
                    VALUES (?,?,1,N'Autorización individual APAPPSS por UOT',?)
                    """,membershipId,permissionId,identity.usuarioId());
        }
        jdbc.update(
                """
                INSERT INTO auditoria.AuditoriaEvento
                    (usuario_id,accion,esquema_entidad,nombre_entidad,identificador,
                     datos_posteriores,motivo,resultado)
                VALUES (?,'ASIGNAR','seg','UsuarioUOTPermiso',?,?,?, 'EXITOSO')
                """, identity.usuarioId(),membershipId+":"+code,
                "{\"permisos\":"+toJsonArray(selected)+"}",
                "Permisos especiales de usuario en UOT "+uotId);
        return AppResult.ok("PERMISOS_USUARIO_ACTUALIZADOS","Permisos guardados.",null);
    }

    private boolean moduleExists(String code) {
        Integer count=jdbc.queryForObject("SELECT COUNT(*) FROM seg.ModuloEspecial WHERE codigo=? AND estado=1",
                Integer.class,code);
        return count!=null && count>0;
    }

    private boolean moduleEnabled(Long uotId,String code) {
        Integer count=jdbc.queryForObject(
                """
                SELECT COUNT(*) FROM seg.ModuloEspecial M
                JOIN org.ConvenioModuloEspecial CM ON CM.modulo_especial_id=M.modulo_especial_id AND CM.estado=1
                JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=CM.convenio_uot_organizacion_id
                JOIN org.Empresa E ON E.empresa_id=C.empresa_id AND E.estado=1
                WHERE M.codigo=? AND M.estado=1 AND C.uot_id=? AND C.estado=1
                  AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(date,SYSUTCDATETIME()))
                  AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(date,SYSUTCDATETIME()))
                """,Integer.class,code,uotId);
        return count!=null && count>0;
    }

    private static String toJsonArray(Set<String> codes) {
        return "["+codes.stream().sorted()
                .map(value->"\""+value.replace("\\","\\\\").replace("\"","\\\"")+"\"")
                .collect(java.util.stream.Collectors.joining(","))+"]";
    }
}
