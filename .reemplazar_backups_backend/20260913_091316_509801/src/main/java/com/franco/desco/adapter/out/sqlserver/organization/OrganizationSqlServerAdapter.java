package com.franco.desco.adapter.out.sqlserver.organization;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.organization.*;
import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.organization.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class OrganizationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements OrganizationPersistencePort {

    public OrganizationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations c, SessionIdentity i, RequestMetadata m) {
        return page("org.PA_Empresa_Sel_Listado", c, i, m, OrganizationModels.Summary.class);
    }

    @Override
    public PersistenceResult<OrganizationModels.Detail> get(GetOrganization c, SessionIdentity i, RequestMetadata m) {
        return one("org.PA_Empresa_Sel_Detalle", c, i, m, OrganizationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> createCompany(CreateCompany c, SessionIdentity i, RequestMetadata m) {
        return create("org.PA_Empresa_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateCompany(UpdateCompany c, SessionIdentity i, RequestMetadata m) {
        return mutate("org.PA_Empresa_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Long> createAssociation(CreateAssociation c, SessionIdentity i, RequestMetadata m) {
        return create("org.PA_Asociacion_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateAssociation(UpdateAssociation c, SessionIdentity i, RequestMetadata m) {
        return mutate("org.PA_Asociacion_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas c, SessionIdentity i, RequestMetadata m) {
        return page("org.PA_Area_Sel_Listado", c, i, m, OrganizationModels.Area.class);
    }

    @Override
    public PersistenceResult<Long> createArea(CreateArea c, SessionIdentity i, RequestMetadata m) {
        return create("org.PA_Area_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateArea(UpdateArea c, SessionIdentity i, RequestMetadata m) {
        return mutate("org.PA_Area_Upd_Registro", c, i, m);
    }

}
