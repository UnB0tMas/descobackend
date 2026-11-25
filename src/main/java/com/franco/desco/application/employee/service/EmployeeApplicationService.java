package com.franco.desco.application.employee.service;

import com.franco.desco.application.employee.EmployeeCommands.*;
import com.franco.desco.application.employee.port.in.EmployeeUseCase;
import com.franco.desco.application.employee.port.out.EmployeePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.application.shared.service.EmailValidationService;
import com.franco.desco.domain.employee.EmployeeModels;

public final class EmployeeApplicationService implements EmployeeUseCase {
    private final EmployeePersistencePort persistence;
    private final EmailValidationService emailValidation;

    public EmployeeApplicationService(EmployeePersistencePort persistence, EmailValidationService emailValidation) {
        this.persistence = persistence;
        this.emailValidation = emailValidation;
    }

    public AppResult<PageResult<EmployeeModels.Summary>> list(ListEmployees c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c, i, m), "EMPLEADOS_LISTADOS", "EMPLEADOS_NO_LISTADOS", AppStatus.BAD_REQUEST);
    }

    public AppResult<EmployeeModels.Detail> get(GetEmployee c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.get(c, i, m), "EMPLEADO_OBTENIDO", "EMPLEADO_NO_DISPONIBLE", AppStatus.NOT_FOUND);
    }

    public AppResult<Long> create(CreateEmployee c, SessionIdentity i, RequestMetadata m) {
        AppResult<Long> error = emailValidation.required(c.correo());
        return error != null ? error : ApplicationResults.created(persistence.create(c, i, m), "EMPLEADO_CREADO", "EMPLEADO_NO_CREADO");
    }

    public AppResult<Void> update(UpdateEmployee c, SessionIdentity i, RequestMetadata m) {
        AppResult<Void> error = emailValidation.ifProvided(c.correo());
        return error != null ? error : ApplicationResults.ok(persistence.update(c, i, m), "EMPLEADO_ACTUALIZADO", "EMPLEADO_NO_ACTUALIZADO", AppStatus.BAD_REQUEST);
    }

    public AppResult<Void> retire(RetireEmployee c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.retire(c, i, m), "EMPLEADO_RETIRADO", "EMPLEADO_NO_RETIRADO", AppStatus.BAD_REQUEST);
    }
}
