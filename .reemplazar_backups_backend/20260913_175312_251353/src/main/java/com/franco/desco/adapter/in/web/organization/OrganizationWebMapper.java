package com.franco.desco.adapter.in.web.organization;

import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.shared.pagination.PageRequest;
import com.franco.desco.domain.organization.OrganizationModels;
import org.springframework.stereotype.Component;

@Component
public class OrganizationWebMapper {

    public CreateCompany command(OrganizationRequests.CreateCompany request) {
        return new CreateCompany(request.ruc(), request.razonSocial(), request.nombreComercial(), request.telefono(), request.correo(), location(request.ubicacion()));
    }

    public UpdateCompany command(Long empresaId, OrganizationRequests.UpdateCompany request) {
        return new UpdateCompany(empresaId, request.razonSocial(), request.nombreComercial(), request.telefono(), request.correo(), location(request.ubicacion()));
    }

    public CreateAssociation command(OrganizationRequests.CreateAssociation request) {
        return new CreateAssociation(request.ruc(), request.razonSocial(), request.nombreComercial(), request.telefono(), request.correo(), request.fechaConstitucion(), request.numeroPartida(), location(request.ubicacion()));
    }

    public UpdateAssociation command(Long asociacionId, OrganizationRequests.UpdateAssociation request) {
        return new UpdateAssociation(asociacionId, request.razonSocial(), request.nombreComercial(), request.telefono(), request.correo(), request.fechaConstitucion(), request.numeroPartida(), location(request.ubicacion()));
    }

    public DisableOrganization disableOrganization(Long empresaId, OrganizationRequests.Disable request) {
        return new DisableOrganization(empresaId, request.motivo());
    }

    public CreateArea command(OrganizationRequests.CreateArea request) {
        return new CreateArea(request.empresaId(), request.areaPadreId(), request.codigo(), request.nombre());
    }

    public UpdateArea command(Long areaId, OrganizationRequests.UpdateArea request) {
        return new UpdateArea(areaId, request.areaPadreId(), request.nombre());
    }

    public DisableArea disableArea(Long areaId, OrganizationRequests.Disable request) {
        return new DisableArea(areaId, request.motivo());
    }

    public ListOrganizations list(int pagina, int tamano) {
        return new ListOrganizations(new PageRequest<>(pagina, tamano, null, null, null));
    }

    public ListAreas listAreas(int pagina, int tamano, Long empresaId) {
        return new ListAreas(new PageRequest<>(pagina, tamano, new AreaFilter(empresaId), null, null));
    }

    public OrganizationResponses.Summary response(OrganizationModels.Summary value) {
        return new OrganizationResponses.Summary(value.empresaId(), value.ruc(), value.razonSocial(), value.nombreComercial(), value.telefono(), value.correo(), value.fechaCreacion(), value.estado(), value.esAsociacion(), value.fechaConstitucion(), value.numeroPartida());
    }

    public OrganizationResponses.Area response(OrganizationModels.Area value) {
        return new OrganizationResponses.Area(value.areaId(), value.empresaId(), value.empresa(), value.areaPadreId(), value.areaPadre(), value.codigo(), value.nombre(), value.estado());
    }

    public OrganizationResponses.Detail response(OrganizationModels.Detail value) {
        return new OrganizationResponses.Detail(
                response(value.organizacion()),
                value.distritoCodigo(),
                value.distritoNombre(),
                value.centroPobladoId(),
                value.centroPobladoNombre(),
                value.referencia(),
                value.altitudM(),
                value.posicionWkt(),
                value.posicionSrid(),
                value.areas().stream().map(this::response).toList(),
                value.empleados().stream()
                        .map(employee -> new OrganizationResponses.Employee(employee.empleadoId(), employee.codigoEmpleado(), employee.numeroDocumento(), employee.empleado()))
                        .toList()
        );
    }

    private LocationInput location(OrganizationRequests.Location value) {
        return new LocationInput(value.distritoCodigo(), value.centroPobladoId(), value.referencia());
    }
}
