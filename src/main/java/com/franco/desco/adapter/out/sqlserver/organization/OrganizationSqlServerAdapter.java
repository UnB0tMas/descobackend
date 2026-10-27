package com.franco.desco.adapter.out.sqlserver.organization;

import com.franco.desco.adapter.out.sqlserver.shared.DatabaseRecordMapper;
import com.franco.desco.adapter.out.sqlserver.shared.JsonPaAdapterSupport;
import com.franco.desco.adapter.out.sqlserver.shared.PaPayloadFactory;
import com.franco.desco.adapter.out.sqlserver.shared.SqlServerPaExecutor;
import com.franco.desco.application.organization.OrganizationCommands.*;
import com.franco.desco.application.organization.port.out.OrganizationPersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.organization.OrganizationModels;
import org.springframework.stereotype.Repository;

@Repository
public final class OrganizationSqlServerAdapter extends JsonPaAdapterSupport implements OrganizationPersistencePort {

    public OrganizationSqlServerAdapter(SqlServerPaExecutor executor, PaPayloadFactory payloads, DatabaseRecordMapper mapper) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Summary>> list(ListOrganizations command, SessionIdentity identity, RequestMetadata metadata) {
        return page("org.PA_Empresa_Sel_Listado", command, identity, metadata, OrganizationModels.Summary.class);
    }

    @Override
    public PersistenceResult<OrganizationModels.Detail> get(GetOrganization command, SessionIdentity identity, RequestMetadata metadata) {
        return one("org.PA_Empresa_Sel_Detalle", command, identity, metadata, OrganizationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> createCompany(CreateCompany command, SessionIdentity identity, RequestMetadata metadata) {
        return create("org.PA_Empresa_Ins_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> updateCompany(UpdateCompany command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("org.PA_Empresa_Upd_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Long> createAssociation(CreateAssociation command, SessionIdentity identity, RequestMetadata metadata) {
        return create("org.PA_Asociacion_Ins_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> updateAssociation(UpdateAssociation command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("org.PA_Asociacion_Upd_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> disableOrganization(DisableOrganization command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("org.PA_Empresa_Upd_DeshabilitarAdministracion", command, identity, metadata);
    }

    @Override
    public PersistenceResult<PageResult<OrganizationModels.Area>> listAreas(ListAreas command, SessionIdentity identity, RequestMetadata metadata) {
        return page("org.PA_Area_Sel_Listado", command, identity, metadata, OrganizationModels.Area.class);
    }

    @Override
    public PersistenceResult<Long> createArea(CreateArea command, SessionIdentity identity, RequestMetadata metadata) {
        return create("org.PA_Area_Ins_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> updateArea(UpdateArea command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("org.PA_Area_Upd_Registro", command, identity, metadata);
    }

    @Override
    public PersistenceResult<Void> disableArea(DisableArea command, SessionIdentity identity, RequestMetadata metadata) {
        return mutate("org.PA_Area_Upd_DeshabilitarAdministracion", command, identity, metadata);
    }
}
