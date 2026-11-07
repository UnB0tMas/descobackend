package com.franco.desco.adapter.in.web.sanitation;

import com.franco.desco.adapter.in.security.JwtSessionIdentityResolver;
import com.franco.desco.adapter.in.web.common.ApiResponse;
import com.franco.desco.adapter.in.web.common.CorrelationIdFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/sanidad/recursos-entregados")
public class SanitationStockController {
    private final JdbcTemplate db;
    private final JwtSessionIdentityResolver identities;
    public SanitationStockController(JdbcTemplate db, JwtSessionIdentityResolver identities) {
        this.db=db; this.identities=identities;
    }
    public record Entregado(Long programacionProductoId,String producto,String unidadMedida,
                            String almacen,BigDecimal cantidadPendiente) {}

    @GetMapping
    @PreAuthorize("@permissionGuard.has(authentication,'SANIDAD_CREAR')")
    public ApiResponse<List<Entregado>> listar(@RequestParam(required=false) Long responsableEmpleadoId,
            JwtAuthenticationToken authentication,HttpServletRequest request) {
        var s=identities.resolve(authentication);
        var items=db.query("""
            SELECT PP.programacion_producto_id,P.nombre,P.unidad_medida,A.nombre almacen,
              PP.cantidad_entregada-PP.cantidad_devuelta-PP.cantidad_consumida pendiente
            FROM logistica.ProgramacionProducto PP
            JOIN logistica.Producto P ON P.producto_id=PP.producto_id
            JOIN logistica.Almacen A ON A.almacen_id=PP.almacen_id
            JOIN seg.SesionUsuario SS ON SS.sesion_publica_id=? AND SS.usuario_id=? AND SS.estado=1
              AND SS.fecha_revocacion IS NULL AND SS.modo_uot='ESPECIFICA' AND SS.uot_contexto_id=PP.uot_id
            JOIN seg.Usuario U ON U.usuario_id=SS.usuario_id
            WHERE PP.estado_proceso='ENTREGADA'
              AND PP.cantidad_entregada>PP.cantidad_devuelta+PP.cantidad_consumida
              AND PP.empleado_id=COALESCE(?,U.persona_id)
              AND (PP.empleado_id=U.persona_id OR seg.FN_Usuario_TienePermisoUOT(U.usuario_id,PP.uot_id,'ALMACENES_MOVIMIENTO')=1)
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,PP.uot_id,'SANIDAD_CREAR')=1
            ORDER BY P.nombre,PP.programacion_producto_id
            """,(r,n)->new Entregado(r.getLong(1),r.getString(2),r.getString(3),r.getString(4),r.getBigDecimal(5)),
                s.sesionPublicaId(),s.usuarioId(),responsableEmpleadoId);
        return new ApiResponse<>(true,"RECURSOS_ENTREGADOS","Productos entregados consultados.",items,
                CorrelationIdFilter.correlationId(request),Instant.now());
    }
}
