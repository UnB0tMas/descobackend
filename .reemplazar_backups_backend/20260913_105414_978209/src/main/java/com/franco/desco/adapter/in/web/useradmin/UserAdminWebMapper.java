package com.franco.desco.adapter.in.web.useradmin;

import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.application.useradmin.UserAdminCommands.*;
import com.franco.desco.domain.useradmin.UserAdminModels;
import org.springframework.stereotype.Component;

@Component
public class UserAdminWebMapper {
    public ListUsers list(int page, int size, String state, Long companyId) {
        return new ListUsers(new PageRequest<>(page,size,new UserFilter(state,companyId),null,null));
    }
    public CreateUser command(UserAdminRequests.Create r) {
        return new CreateUser(r.empleadoId(),r.nombreUsuario(),r.passwordInicial(),r.correoSeguridad(),r.requiereCambioPassword(),r.rolIds());
    }
    public UpdateUser command(Long id, UserAdminRequests.Update r) {
        return new UpdateUser(id,r.nombreUsuario(),r.requiereCambioPassword(),r.segundoFactorHabilitado());
    }
    public DisableUser command(Long id, UserAdminRequests.Disable r) { return new DisableUser(id,r.motivo()); }
    public ReactivateUser command(Long id, UserAdminRequests.Reactivate r) { return new ReactivateUser(id,r.motivo()); }
    public AssignRole command(Long id, UserAdminRequests.AssignRole r) { return new AssignRole(id,r.rolId()); }
    public RemoveRole command(Long id, UserAdminRequests.RemoveRole r) { return new RemoveRole(id,r.rolId(),r.motivo()); }

    public UserAdminResponses.Summary response(UserAdminModels.Summary x) {
        return new UserAdminResponses.Summary(x.usuarioId(),x.nombreUsuario(),x.estadoCuenta(),x.fechaCreacion(),x.ultimoAccesoCorrecto(),x.intentosFallidos(),x.bloqueadoHasta(),x.segundoFactorHabilitado(),x.empleadoId(),x.codigoEmpleado(),x.empresa(),x.numeroDocumento(),x.empleado(),x.rolesActivos(),x.sesionesActivas());
    }
    public UserAdminResponses.Detail response(UserAdminModels.Detail x) {
        return new UserAdminResponses.Detail(x.usuarioId(),x.nombreUsuario(),x.estadoCuenta(),x.estado(),x.fechaCreacion(),x.ultimoAccesoCorrecto(),x.fechaCambioPassword(),x.requiereCambioPassword(),x.segundoFactorHabilitado(),x.empleadoId(),x.numeroDocumento(),x.empleado(),x.roles().stream().map(r->new UserAdminResponses.Role(r.rolId(),r.codigo(),r.nombre(),r.fechaDesde(),r.fechaHasta(),r.estado())).toList(),x.dispositivos().stream().map(d->new UserAdminResponses.Device(d.dispositivoUsuarioId(),d.navegador(),d.sistemaOperativo(),d.primeraDeteccion(),d.ultimaActividad(),d.esReconocido(),d.fechaReconocimiento(),d.fechaRetiroReconocimiento(),d.estado())).toList());
    }
}
