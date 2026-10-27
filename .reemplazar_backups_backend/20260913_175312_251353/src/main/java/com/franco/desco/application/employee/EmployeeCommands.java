package com.franco.desco.application.employee;

import com.franco.desco.application.shared.pagination.PageRequest;

import java.time.LocalDate;

public final class EmployeeCommands {

    private EmployeeCommands() {
    }

    public record Filter(
            Long empresaId,
            Long areaId,
            Boolean activo
    ) {
    }

    public record ListEmployees(
            PageRequest<Filter> page
    ) {
    }

    public record GetEmployee(
            Long empleadoId
    ) {
    }

    public record LocationInput(
            String distritoCodigo,
            Long centroPobladoId,
            String referencia
    ) {
    }

    public record CreateEmployee(
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            Long empresaId,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            Long areaId,
            String cargo,
            LocationInput ubicacion
    ) {
    }

    public record UpdateEmployee(
            Long empleadoId,
            String tipoDocumento,
            String numeroDocumento,
            String nombres,
            String apellidoPaterno,
            String apellidoMaterno,
            String telefono,
            String correo,
            LocalDate fechaNacimiento,
            Long empresaId,
            String codigoEmpleado,
            LocalDate fechaIngreso,
            Long areaId,
            String cargo,
            LocalDate fechaAsignacionArea,
            LocationInput ubicacion
    ) {
    }

    public record RetireEmployee(
            Long empleadoId,
            String motivo,
            LocalDate fechaCese
    ) {
    }
}
