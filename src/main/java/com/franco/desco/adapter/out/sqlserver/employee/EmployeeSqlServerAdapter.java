package com.franco.desco.adapter.out.sqlserver.employee;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.employee.*;
import com.franco.desco.application.employee.EmployeeCommands.*;
import com.franco.desco.application.employee.port.out.EmployeePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.employee.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class EmployeeSqlServerAdapter
        extends JsonPaAdapterSupport
        implements EmployeePersistencePort {

    public EmployeeSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<EmployeeModels.Summary>> list(ListEmployees c,SessionIdentity i,RequestMetadata m) {
        return page("org.PA_Empleado_Sel_Listado", c, i, m, EmployeeModels.Summary.class);
    }

    @Override
    public PersistenceResult<EmployeeModels.Detail> get(GetEmployee c,SessionIdentity i,RequestMetadata m) {
        return one("org.PA_Empleado_Sel_Detalle", c, i, m, EmployeeModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateEmployee c,SessionIdentity i,RequestMetadata m) {
        return create("org.PA_Empleado_Ins_RegistroAdministracion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateEmployee c,SessionIdentity i,RequestMetadata m) {
        return mutate("org.PA_Empleado_Upd_RegistroAdministracion", c, i, m);
    }

    @Override
    public PersistenceResult<Void> retire(RetireEmployee c,SessionIdentity i,RequestMetadata m) {
        return mutate("org.PA_Empleado_Upd_RetirarAdministracion", c, i, m);
    }

}
