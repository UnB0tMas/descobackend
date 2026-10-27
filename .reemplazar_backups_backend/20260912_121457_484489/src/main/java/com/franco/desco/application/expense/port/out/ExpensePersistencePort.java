package com.franco.desco.application.expense.port.out;

import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.expense.ExpenseModels;

public interface ExpensePersistencePort {
    PersistenceResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(ExpenseCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> update(ExpenseCommands.Update command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> prorate(ExpenseCommands.Prorate command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> approve(ExpenseCommands.Approve command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(ExpenseCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
