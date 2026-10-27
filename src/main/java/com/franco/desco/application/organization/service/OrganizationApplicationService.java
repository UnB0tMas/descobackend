package com.franco.desco.application.organization.service;

import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.organization.port.in.OrganizationUseCase;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.AppStatus;
import com.franco.desco.application.shared.ApplicationResults;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;

public final class OrganizationApplicationService implements OrganizationUseCase {

    private final OrganizationPersistencePort persistence;

    public OrganizationApplicationService(OrganizationPersistencePort persistence) {
        this.persistence = persistence;
    }

    @Override
    public AppResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.list(command, identity, metadata), "ORGANIZACIONES_LISTADAS", "ORGANIZACIONES_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<OrganizationModels.Detail> get(GetOrganization command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.get(command, identity, metadata), "ORGANIZACION_OBTENIDA", "ORGANIZACION_NO_DISPONIBLE", AppStatus.NOT_FOUND);
    }

    @Override
    public AppResult<Long> createCompany(CreateCompany command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.created(persistence.createCompany(command, identity, metadata), "EMPRESA_CREADA", "EMPRESA_NO_CREADA");
    }

    @Override
    public AppResult<Void> updateCompany(UpdateCompany command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.updateCompany(command, identity, metadata), "EMPRESA_ACTUALIZADA", "EMPRESA_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Long> createAssociation(CreateAssociation command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.created(persistence.createAssociation(command, identity, metadata), "ASOCIACION_CREADA", "ASOCIACION_NO_CREADA");
    }

    @Override
    public AppResult<Void> updateAssociation(UpdateAssociation command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.updateAssociation(command, identity, metadata), "ASOCIACION_ACTUALIZADA", "ASOCIACION_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Void> disableOrganization(DisableOrganization command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.disableOrganization(command, identity, metadata), "ORGANIZACION_DESHABILITADA", "ORGANIZACION_NO_DESHABILITADA", AppStatus.CONFLICT);
    }

    @Override
    public AppResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.listAreas(command, identity, metadata), "AREAS_LISTADAS", "AREAS_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Long> createArea(CreateArea command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.created(persistence.createArea(command, identity, metadata), "AREA_CREADA", "AREA_NO_CREADA");
    }

    @Override
    public AppResult<Void> updateArea(UpdateArea command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.updateArea(command, identity, metadata), "AREA_ACTUALIZADA", "AREA_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }

    @Override
    public AppResult<Void> disableArea(DisableArea command, SessionIdentity identity, RequestMetadata metadata) {
        return ApplicationResults.ok(persistence.disableArea(command, identity, metadata), "AREA_DESHABILITADA", "AREA_NO_DESHABILITADA", AppStatus.CONFLICT);
    }
}
