package com.franco.desco.adapter.out.sqlserver.cultivation;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.cultivation.*;
import com.franco.desco.application.cultivation.CultivationCommands.*;
import com.franco.desco.application.cultivation.port.out.CultivationPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.cultivation.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class CultivationSqlServerAdapter
        extends JsonPaAdapterSupport
        implements CultivationPersistencePort {

    public CultivationSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<CultivationModels.Summary>> list(ListCultivations c,SessionIdentity i,RequestMetadata m) {
        return page("prod.PA_ParcelaCultivo_Sel_Listado", c, i, m, CultivationModels.Summary.class);
    }

    @Override
    public PersistenceResult<CultivationModels.Detail> get(GetCultivation c,SessionIdentity i,RequestMetadata m) {
        return one("prod.PA_ParcelaCultivo_Sel_DetalleExpediente", c, i, m, CultivationModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> createPlot(CreatePlot c,SessionIdentity i,RequestMetadata m) {
        return create("prod.PA_Parcela_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updatePlot(UpdatePlot c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_Parcela_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Long> createCrop(CreateCrop c,SessionIdentity i,RequestMetadata m) {
        return create("prod.PA_Cultivo_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updateCrop(UpdateCrop c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_Cultivo_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> finishCrop(FinishCrop c,SessionIdentity i,RequestMetadata m) {
        return mutate("prod.PA_Cultivo_Upd_Finalizar", c, i, m);
    }

}
