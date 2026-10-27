package com.franco.desco.application.organization.port.in;

import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;

public interface OrganizationUseCase {
    AppResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<OrganizationModels.Detail> get(GetOrganization command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> createCompany(CreateCompany command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> updateCompany(UpdateCompany command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> createAssociation(CreateAssociation command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> updateAssociation(UpdateAssociation command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> createArea(CreateArea command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> updateArea(UpdateArea command, SessionIdentity identity, RequestMetadata metadata);
}
