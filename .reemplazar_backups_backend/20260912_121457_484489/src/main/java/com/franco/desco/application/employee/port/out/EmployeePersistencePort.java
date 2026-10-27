package com.franco.desco.application.employee.port.out;

import com.franco.desco.application.employee.EmployeeCommands.CreateEmployee;
import com.franco.desco.application.employee.EmployeeCommands.GetEmployee;
import com.franco.desco.application.employee.EmployeeCommands.ListEmployees;
import com.franco.desco.application.employee.EmployeeCommands.RetireEmployee;
import com.franco.desco.application.employee.EmployeeCommands.UpdateEmployee;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.RequestMetadata;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.employee.EmployeeModels;

public interface EmployeePersistencePort {

    PersistenceResult<PageResult<EmployeeModels.Summary>> list(
            ListEmployees command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<EmployeeModels.Detail> get(
            GetEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Long> create(
            CreateEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> update(
            UpdateEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    );

    PersistenceResult<Void> retire(
            RetireEmployee command,
            SessionIdentity identity,
            RequestMetadata metadata
    );
}
