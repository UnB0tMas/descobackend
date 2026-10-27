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
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocationInput ubicacion
    ) {
    }

    public record CreateAssociation(
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
            String razonSocial,
            String nombreComercial,
            String telefono,
            String correo,
            LocalDate fechaConstitucion,
            String numeroPartida,
            LocationInput ubicacion
    ) {
    }

    public record AreaFilter(Long empresaId) {
    }

    public record ListAreas(PageRequest<AreaFilter> page) {
    }

    public record CreateArea(
            Long empresaId,
            Long areaPadreId,
            String codigo,
            String nombre
    ) {
    }

    public record UpdateArea(
            Long areaId,
            Long areaPadreId,
            String nombre
    ) {
    }
}
