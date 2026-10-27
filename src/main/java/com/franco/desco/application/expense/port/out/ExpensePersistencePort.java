package com.franco.desco.application.expense.port.out;

import com.franco.desco.application.expense.*;
import com.franco.desco.application.expense.ExpenseCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.expense.*;
import java.util.*;

public interface ExpensePersistencePort {
    PersistenceResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Long> create(ExpenseCommands.Create c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> update(ExpenseCommands.Update c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> prorate(ExpenseCommands.Prorate c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> approve(ExpenseCommands.Approve c,SessionIdentity i,RequestMetadata m);
    PersistenceResult<Void> cancel(ExpenseCommands.Cancel c,SessionIdentity i,RequestMetadata m);
}
