package com.franco.desco.application.organization.port.out;

import com.franco.desco.application.organization.*;
import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.*;
import java.util.*;

public interface OrganizationPersistencePort {
    PersistenceResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<OrganizationModels.Detail> get(GetOrganization c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> createCompany(CreateCompany c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> updateCompany(UpdateCompany c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> createAssociation(CreateAssociation c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> updateAssociation(UpdateAssociation c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> createArea(CreateArea c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> updateArea(UpdateArea c, SessionIdentity i, RequestMetadata m);
}
