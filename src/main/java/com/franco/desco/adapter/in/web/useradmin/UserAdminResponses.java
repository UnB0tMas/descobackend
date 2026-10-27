package com.franco.desco.adapter.in.web.useradmin;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;

public final class UserAdminResponses {
    private UserAdminResponses() {}

    @Schema(name="UserAdminSummaryResponse")
    public record Summary(Long usuarioId,String nombreUsuario,String estadoCuenta,Instant fechaCreacion,Instant ultimoAccesoCorrecto,Integer intentosFallidos,Instant bloqueadoHasta,boolean segundoFactorHabilitado,Long empleadoId,String codigoEmpleado,String empresa,String numeroDocumento,String empleado,long rolesActivos,long sesionesActivas) {}

    @Schema(name="UserAdminRoleResponse")
    public record Role(Long rolId,String codigo,String nombre,Instant fechaDesde,Instant fechaHasta,boolean estado) {}

    @Schema(name="UserAdminDeviceResponse")
    public record Device(Long dispositivoUsuarioId,String navegador,String sistemaOperativo,Instant primeraDeteccion,Instant ultimaActividad,boolean esReconocido,Instant fechaReconocimiento,Instant fechaRetiroReconocimiento,boolean estado) {}

    @Schema(name="SecurityPolicyDeviceTrustResponse")
    public record SecurityPolicy(Integer diasDispositivoReconocido) {}

    @Schema(name="UserAdminDetailResponse")
    public record Detail(Long usuarioId,String nombreUsuario,String estadoCuenta,boolean estado,Instant fechaCreacion,Instant ultimoAccesoCorrecto,Instant fechaCambioPassword,boolean requiereCambioPassword,boolean segundoFactorHabilitado,Long empleadoId,String numeroDocumento,String empleado,List<Role>roles,List<Device>dispositivos) {}

    @Schema(name="UserAdminCreatedResponse")
    public record Created(Long usuarioId) {}
}
