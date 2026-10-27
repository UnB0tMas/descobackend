package com.franco.desco.adapter.in.web.employee;

import com.franco.desco.application.employee.EmployeeCommands.CreateEmployee;
import com.franco.desco.application.employee.EmployeeCommands.Filter;
import com.franco.desco.application.employee.EmployeeCommands.ListEmployees;
import com.franco.desco.application.employee.EmployeeCommands.LocationInput;
import com.franco.desco.application.employee.EmployeeCommands.RetireEmployee;
import com.franco.desco.application.employee.EmployeeCommands.UpdateEmployee;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.employee.EmployeeModels;
import org.springframework.stereotype.Component;

@Component
public class EmployeeWebMapper {

    public ListEmployees list(
            int pagina,
            int tamano,
            Long empresaId,
            Long areaId,
            Boolean activo
    ) {
        return new ListEmployees(
                new PageRequest<>(
                        pagina,
                        tamano,
                        new Filter(
                                empresaId,
                                areaId,
                                activo
                        ),
                        null,
                        null
                )
        );
    }

    public CreateEmployee command(
            EmployeeRequests.Create request
    ) {
        return new CreateEmployee(
                request.tipoDocumento(),
                request.numeroDocumento(),
                request.nombres(),
                request.apellidoPaterno(),
                request.apellidoMaterno(),
                request.telefono(),
                request.correo(),
                request.fechaNacimiento(),
                request.empresaId(),
                request.codigoEmpleado(),
                request.fechaIngreso(),
                request.areaId(),
                request.cargo(),
                location(request.ubicacion())
        );
    }

    public UpdateEmployee command(
            Long empleadoId,
            EmployeeRequests.Update request
    ) {
        return new UpdateEmployee(
                empleadoId,
                request.tipoDocumento(),
                request.numeroDocumento(),
                request.nombres(),
                request.apellidoPaterno(),
                request.apellidoMaterno(),
                request.telefono(),
                request.correo(),
                request.fechaNacimiento(),
                request.empresaId(),
                request.codigoEmpleado(),
                request.fechaIngreso(),
                request.areaId(),
                request.cargo(),
                request.fechaAsignacionArea(),
                location(request.ubicacion())
        );
    }

    public RetireEmployee command(
            Long empleadoId,
            EmployeeRequests.Retire request
    ) {
        return new RetireEmployee(
                empleadoId,
                request.motivo(),
                request.fechaCese()
        );
    }

    public EmployeeResponses.Summary response(
            EmployeeModels.Summary value
    ) {
        return new EmployeeResponses.Summary(
                value.empleadoId(),
                value.empresaId(),
                value.empresa(),
                value.codigoEmpleado(),
                value.fechaIngreso(),
                value.fechaCese(),
                value.estado(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.areaId(),
                value.area(),
                value.cargo(),
                value.usuarioId(),
                value.nombreUsuario(),
                value.estadoCuenta()
        );
    }

    public EmployeeResponses.Detail response(
            EmployeeModels.Detail value
    ) {
        return new EmployeeResponses.Detail(
                value.empleadoId(),
                value.empresaId(),
                value.empresa(),
                value.codigoEmpleado(),
                value.fechaIngreso(),
                value.fechaCese(),
                value.estado(),
                value.tipoDocumento(),
                value.numeroDocumento(),
                value.nombres(),
                value.apellidoPaterno(),
                value.apellidoMaterno(),
                value.telefono(),
                value.correo(),
                value.fechaNacimiento(),
                value.distritoCodigo(),
                value.distritoNombre(),
                value.centroPobladoId(),
                value.centroPobladoNombre(),
                value.referencia(),
                value.areas()
                        .stream()
                        .map(area ->
                                new EmployeeResponses.AreaHistory(
                                        area.empleadoAreaId(),
                                        area.areaId(),
                                        area.area(),
                                        area.cargo(),
                                        area.fechaDesde(),
                                        area.fechaHasta(),
                                        area.estado()
                                )
                        )
                        .toList(),
                value.usuario() == null
                        ? null
                        : new EmployeeResponses.User(
                                value.usuario().usuarioId(),
                                value.usuario().nombreUsuario(),
                                value.usuario().estadoCuenta(),
                                value.usuario().ultimoAccesoCorrecto(),
                                value.usuario().segundoFactorHabilitado()
                        ),
                value.roles()
                        .stream()
                        .map(role ->
                                new EmployeeResponses.Role(
                                        role.rolId(),
                                        role.codigo(),
                                        role.nombre(),
                                        role.fechaDesde(),
                                        role.fechaHasta(),
                                        role.estado()
                                )
                        )
                        .toList()
        );
    }

    private LocationInput location(
            EmployeeRequests.Location location
    ) {
        return new LocationInput(
                location.distritoCodigo(),
                location.centroPobladoId(),
                location.referencia()
        );
    }
}
