package com.franco.desco.application.organization.service;

import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.organization.port.in.OrganizationUseCase;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;

public final class OrganizationApplicationService implements OrganizationUseCase {
    private final OrganizationPersistencePort persistence;
    public OrganizationApplicationService(OrganizationPersistencePort persistence) { this.persistence = persistence; }

    public AppResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c,i,m), "ORGANIZACIONES_LISTADAS", "ORGANIZACIONES_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }
    public AppResult<OrganizationModels.Detail> get(GetOrganization c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.get(c,i,m), "ORGANIZACION_OBTENIDA", "ORGANIZACION_NO_DISPONIBLE", AppStatus.NOT_FOUND);
    }
    public AppResult<Long> createCompany(CreateCompany c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.createCompany(c,i,m), "EMPRESA_CREADA", "EMPRESA_NO_CREADA");
    }
    public AppResult<Void> updateCompany(UpdateCompany c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.updateCompany(c,i,m), "EMPRESA_ACTUALIZADA", "EMPRESA_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }
    public AppResult<Long> createAssociation(CreateAssociation c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.createAssociation(c,i,m), "ASOCIACION_CREADA", "ASOCIACION_NO_CREADA");
    }
    public AppResult<Void> updateAssociation(UpdateAssociation c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.updateAssociation(c,i,m), "ASOCIACION_ACTUALIZADA", "ASOCIACION_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }
    public AppResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.listAreas(c,i,m), "AREAS_LISTADAS", "AREAS_NO_LISTADAS", AppStatus.BAD_REQUEST);
    }
    public AppResult<Long> createArea(CreateArea c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.createArea(c,i,m), "AREA_CREADA", "AREA_NO_CREADA");
    }
    public AppResult<Void> updateArea(UpdateArea c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.updateArea(c,i,m), "AREA_ACTUALIZADA", "AREA_NO_ACTUALIZADA", AppStatus.BAD_REQUEST);
    }
}
