package com.franco.desco.application.expense.service;

import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.expense.port.in.ExpenseUseCase;
import com.franco.desco.application.expense.port.out.ExpensePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.expense.ExpenseModels;

public final class ExpenseApplicationService implements ExpenseUseCase {
    private final ExpensePersistencePort persistence;
    public ExpenseApplicationService(ExpensePersistencePort persistence){this.persistence=persistence;}

    public AppResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.list(c,i,m),"GASTOS_LISTADOS","GASTOS_NO_LISTADOS",AppStatus.BAD_REQUEST);
    }
    public AppResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.get(c,i,m),"GASTO_CONSULTADO","GASTO_NO_DISPONIBLE",AppStatus.BAD_REQUEST);
    }
    public AppResult<Long> create(ExpenseCommands.Create c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.created(persistence.create(c,i,m),"GASTO_REGISTRADO","GASTO_NO_REGISTRADO");
    }
    public AppResult<Void> update(ExpenseCommands.Update c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.update(c,i,m),"GASTO_ACTUALIZADO","GASTO_NO_ACTUALIZADO",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> prorate(ExpenseCommands.Prorate c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.prorate(c,i,m),"GASTO_PRORRATEADO","GASTO_NO_PRORRATEADO",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> approve(ExpenseCommands.Approve c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.approve(c,i,m),"GASTO_APROBADO","GASTO_NO_APROBADO",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> cancel(ExpenseCommands.Cancel c,SessionIdentity i,RequestMetadata m){
        return ApplicationResults.ok(persistence.cancel(c,i,m),"GASTO_ANULADO","GASTO_NO_ANULADO",AppStatus.BAD_REQUEST);
    }
}
