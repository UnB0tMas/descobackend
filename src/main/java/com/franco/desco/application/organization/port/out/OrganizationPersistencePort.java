package com.franco.desco.application.organization.port.out;

import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;

public interface OrganizationPersistencePort {
    PersistenceResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<OrganizationModels.Detail> get(GetOrganization command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> createCompany(CreateCompany command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> updateCompany(UpdateCompany command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> createAssociation(CreateAssociation command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> updateAssociation(UpdateAssociation command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> disableOrganization(DisableOrganization command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> createArea(CreateArea command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> updateArea(UpdateArea command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> disableArea(DisableArea command, SessionIdentity identity, RequestMetadata metadata);
}
