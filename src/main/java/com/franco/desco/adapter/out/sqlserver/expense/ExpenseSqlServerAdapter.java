package com.franco.desco.adapter.out.sqlserver.expense;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.expense.*;
import com.franco.desco.application.expense.ExpenseCommands.*;
import com.franco.desco.application.expense.port.out.ExpensePersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.expense.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class ExpenseSqlServerAdapter
        extends JsonPaAdapterSupport
        implements ExpensePersistencePort {

    public ExpenseSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<ExpenseModels.Summary>> list(ExpenseCommands.ListExpenses c,SessionIdentity i,RequestMetadata m) {
        return page("finanzas.PA_GastoCampania_Sel_Listado", c, i, m, ExpenseModels.Summary.class);
    }

    @Override
    public PersistenceResult<ExpenseModels.Detail> get(ExpenseCommands.GetExpense c,SessionIdentity i,RequestMetadata m) {
        return one("finanzas.PA_GastoCampania_Sel_Detalle", c, i, m, ExpenseModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(ExpenseCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("finanzas.PA_GastoCampania_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(ExpenseCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_GastoCampania_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> prorate(ExpenseCommands.Prorate c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_GastoCampania_Ins_EjecutarProrrateo", c, i, m);
    }

    @Override
    public PersistenceResult<Void> approve(ExpenseCommands.Approve c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_GastoCampania_Upd_Aprobar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(ExpenseCommands.Cancel c,SessionIdentity i,RequestMetadata m) {
        return mutate("finanzas.PA_GastoCampania_Upd_Anular", c, i, m);
    }

}
