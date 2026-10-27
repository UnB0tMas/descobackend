package com.franco.desco.domain.useradmin;

import java.time.Instant;
import java.util.List;

public final class UserAdminModels {
    private UserAdminModels() {}

    public record Summary(Long usuarioId,String nombreUsuario,String estadoCuenta,Instant fechaCreacion,Instant ultimoAccesoCorrecto,Integer intentosFallidos,Instant bloqueadoHasta,boolean segundoFactorHabilitado,Long empleadoId,String codigoEmpleado,String empresa,String numeroDocumento,String empleado,long rolesActivos,long sesionesActivas) {}
    public record Role(Long rolId,String codigo,String nombre,Instant fechaDesde,Instant fechaHasta,boolean estado) {}
    public record Device(Long dispositivoUsuarioId,String navegador,String sistemaOperativo,Instant primeraDeteccion,Instant ultimaActividad,boolean esReconocido,Instant fechaReconocimiento,Instant fechaRetiroReconocimiento,boolean estado) {}
    public record SecurityPolicy(Integer diasDispositivoReconocido) {}
    public record Detail(Long usuarioId,String nombreUsuario,String estadoCuenta,boolean estado,Instant fechaCreacion,Instant ultimoAccesoCorrecto,Instant fechaCambioPassword,boolean requiereCambioPassword,boolean segundoFactorHabilitado,Long empleadoId,String numeroDocumento,String empleado,List<Role>roles,List<Device>dispositivos) {
        public Detail {
            roles=roles==null?List.of():List.copyOf(roles);
            dispositivos=dispositivos==null?List.of():List.copyOf(dispositivos);
        }
    }
}
