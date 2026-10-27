package com.franco.desco.application.expense.port.in;

import com.franco.desco.application.expense.ExpenseCommands;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.expense.ExpenseModels;

public interface ExpenseUseCase {
    AppResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(ExpenseCommands.Create command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> update(ExpenseCommands.Update command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> prorate(ExpenseCommands.Prorate command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> approve(ExpenseCommands.Approve command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(ExpenseCommands.Cancel command, SessionIdentity identity, RequestMetadata metadata);
}
