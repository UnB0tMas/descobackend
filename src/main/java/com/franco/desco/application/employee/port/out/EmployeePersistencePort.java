package com.franco.desco.application.employee.port.out;

import com.franco.desco.application.employee.*;
import com.franco.desco.application.employee.EmployeeCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.employee.*;
import java.util.*;

public interface EmployeePersistencePort {
    PersistenceResult<PageResult<EmployeeModels.Summary>> list(ListEmployees c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<EmployeeModels.Detail> get(GetEmployee c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(CreateEmployee c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(UpdateEmployee c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> retire(RetireEmployee c,SessionIdentity i,RequestMetadata m);
}
