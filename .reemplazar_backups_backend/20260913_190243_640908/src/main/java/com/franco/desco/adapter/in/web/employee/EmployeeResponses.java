package com.franco.desco.adapter.in.web.employee;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class EmployeeResponses {

    private EmployeeResponses() {
    }

    @Schema(name = "EmployeeSummaryResponse")
    public record Summary(
            Long empleadoId,
            Long empresaId,
            String empresa,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            LocalDate fechaCese,
            boolean estado,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            Long areaId,
            String area,
            String cargo,
            Long usuarioId,
            String nombreUsuario,
            String estadoCuenta
    ) {
    }

    @Schema(name = "EmployeeAreaHistoryResponse")
    public record AreaHistory(
            Long empleadoAreaId,
            Long areaId,
            String area,
            String cargo,
            LocalDate fechaDesde,
            LocalDate fechaHasta,
            boolean estado
    ) {
    }

    @Schema(name = "EmployeeUserResponse")
    public record User(
            Long usuarioId,
            String nombreUsuario,
            String estadoCuenta,
            Instant ultimoAccesoCorrecto,
            boolean segundoFactorHabilitado
    ) {
    }

    @Schema(name = "EmployeeRoleResponse")
    public record Role(
            Long rolId,
            String codigo,
            String nombre,
            Instant fechaDesde,
            Instant fechaHasta,
            boolean estado
    ) {
    }

    @Schema(name = "EmployeeDetailResponse")
    public record Detail(
            Long empleadoId,
            Long empresaId,
            String empresa,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            LocalDate fechaCese,
            boolean estado,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            String distritoCodigo,
            String distritoNombre,
            Long centroPobladoId,
            String centroPobladoNombre,
            String referencia,
            List<AreaHistory> areas,
            User usuario,
            List<Role> roles
    ) {
    }

    @Schema(name = "EmployeeCreatedResponse")
    public record Created(
            Long empleadoId
    ) {
    }
}
