package com.franco.desco.application.organization;

import com.franco.desco.application.shared.pagination.PageRequest;

import java.time.LocalDate;

public final class OrganizationCommands {

    private OrganizationCommands() {
    }

    public record ListOrganizations(PageRequest<Void> page) {
    }

    public record GetOrganization(Long empresaId) {
    }

    public record LocationInput(
            String distritoCodigo,
            Long centroPobladoId,
            String referencia
    ) {
    }

    public record CreateCompany(
            Long uotId,
            String ruc,
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocationInput ubicacion
    ) {
    }

    public record UpdateCompany(
            Long empresaId,
            Long uotId,
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocationInput ubicacion
    ) {
    }

    public record CreateAssociation(
            Long uotId,
            String ruc,
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocalDate fechaConstitucion,
            String numeroPartida,
            LocationInput ubicacion
    ) {
    }

    public record UpdateAssociation(
            Long asociacionId,
            Long uotId,
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocalDate fechaConstitucion,
            String numeroPartida,
            LocationInput ubicacion
    ) {
    }

    public record DisableOrganization(
            Long empresaId,
            String motivo
    ) {
    }

    public record AreaFilter(
            Long empresaId,
            Long uotId
    ) {
    }

    public record ListAreas(PageRequest<AreaFilter> page) {
    }

    public record CreateArea(
            Long empresaId,
            Long uotId,
            Long areaPadreId,
            String codigo,
            String nombre
    ) {
    }

    public record UpdateArea(
            Long areaId,
            Long uotId,
            Long areaPadreId,
            String nombre
    ) {
    }

    public record DisableArea(
            Long areaId,
            String motivo
    ) {
    }
}
