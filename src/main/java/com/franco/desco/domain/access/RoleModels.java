package com.franco.desco.domain.access;

import java.time.Instant;
import java.util.List;

public final class RoleModels {
    private RoleModels(){}
    public record Summary(Long rolId,String codigo,String nombre,String descripcion,boolean requiereSegundoFactor,boolean esSistema,boolean estado,long usuariosActivos,long permisosActivos){}
    public record Permission(Long permisoId,String codigo,String nombre,String accion,boolean esSensible,boolean requiereMotivo,String moduloCodigo,String moduloNombre,boolean estado){}
    public record User(Long usuarioId,String nombreUsuario,String numeroDocumento,String empleado,Instant fechaDesde,Instant fechaHasta,boolean estado){}
    public record Detail(Summary rol,List<Permission> permisos,List<User> usuarios){public Detail{permisos=permisos==null?List.of():List.copyOf(permisos);usuarios=usuarios==null?List.of():List.copyOf(usuarios);}}
}
