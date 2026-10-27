package com.franco.desco.adapter.in.web.access;
import io.swagger.v3.oas.annotations.media.Schema; import java.time.Instant; import java.util.List;
public final class RoleResponses{private RoleResponses(){}
 @Schema(name="RoleSummaryResponse") public record Summary(Long rolId,String codigo,String nombre,String descripcion,boolean requiereSegundoFactor,boolean esSistema,boolean estado,long usuariosActivos,long permisosActivos){}
 @Schema(name="RolePermissionResponse") public record Permission(Long permisoId,String codigo,String nombre,String accion,boolean esSensible,boolean requiereMotivo,String moduloCodigo,String moduloNombre,boolean estado){}
 @Schema(name="RoleUserResponse") public record User(Long usuarioId,String nombreUsuario,String numeroDocumento,String empleado,Instant fechaDesde,Instant fechaHasta,boolean estado){}
 @Schema(name="RoleDetailResponse") public record Detail(Summary rol,List<Permission> permisos,List<User> usuarios){}
 @Schema(name="RoleCreatedResponse") public record Created(Long rolId){}
}
