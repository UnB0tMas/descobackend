package com.franco.desco.application.access;
import com.franco.desco.application.shared.pagination.PageRequest;
import java.util.List;
public final class RoleCommands { private RoleCommands(){}
    public record ListRoles(PageRequest<Void> page){}
    public record GetRole(Long rolId){}
    public record CreateRole(String codigo,String nombre,String descripcion,boolean requiereSegundoFactor){}
    public record UpdateRole(Long rolId,String nombre,String descripcion,boolean requiereSegundoFactor){}
    public record DisableRole(Long rolId,String motivo){}
    public record UpdatePermissions(Long rolId,List<Long> permisoIds,String motivo){public UpdatePermissions{permisoIds=permisoIds==null?List.of():List.copyOf(permisoIds);}}
}
