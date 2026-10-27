package com.franco.desco.adapter.out.sqlserver.census;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.census.*;
import com.franco.desco.application.census.CensusCommands.*;
import com.franco.desco.application.census.port.out.CensusPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.census.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CensusSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CensusPersistencePort {

    public CensusSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CensusModels.Summary>> list(ListCensuses c,SessionIdentity i,RequestMetadata m) {
        return page("prod.PA_CensoPlantas_Sel_Historial", c, i, m, CensusModels.Summary.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateCensus c,SessionIdentity i,RequestMetadata m) {
        return create("prod.PA_CensoPlantas_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateCensus c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_CensoPlantas_Upd_Registro", c, i, m);
    }

}
