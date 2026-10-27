package com.franco.desco.adapter.out.sqlserver.evaluation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.evaluation.*;
import com.franco.desco.application.evaluation.EvaluationCommands.*;
import com.franco.desco.application.evaluation.port.out.EvaluationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.evaluation.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class EvaluationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements EvaluationPersistencePort {

    public EvaluationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<EvaluationModels.Summary>> list(EvaluationCommands.ListEvaluations c,SessionIdentity i,RequestMetadata m) {
        return page("campo.PA_EvaluacionAgronomica_Sel_Listado", c, i, m, EvaluationModels.Summary.class);
    }

    @Override
    public PersistenceResult<EvaluationModels.Detail> get(EvaluationCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("campo.PA_EvaluacionAgronomica_Sel_Detalle", c, i, m, EvaluationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(EvaluationCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("campo.PA_EvaluacionAgronomica_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(EvaluationCommands.Update c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_EvaluacionAgronomica_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> registerDryMatter(EvaluationCommands.RegisterDryMatter c,SessionIdentity i,RequestMetadata m) {
        return mutate("campo.PA_EvaluacionMateriaSeca_Ins_Registro", c, i, m);
    }

}
