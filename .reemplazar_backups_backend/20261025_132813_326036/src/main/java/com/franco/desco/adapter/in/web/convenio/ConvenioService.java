package com.franco.desco.adapter.in.web.convenio;

import com.franco.desco.adapter.in.security.UotAuthorizationService;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

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
                ORDER BY M.nombre
                """, (rs, index) -> new ConvenioModuloResponse(rs.getString(1), rs.getString(2), true), uotId));
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
}
