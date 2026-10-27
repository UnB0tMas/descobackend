package com.franco.desco.adapter.out.sqlserver.producer;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.producer.*;
import com.franco.desco.application.producer.ProducerCommands.*;
import com.franco.desco.application.producer.port.out.ProducerPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.producer.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class ProducerSqlServerAdapter
        extends JsonPaAdapterSupport
        implements ProducerPersistencePort {

    public ProducerSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<ProducerModels.Summary>> list(ListProducers c, SessionIdentity i, RequestMetadata m) {
        return page("org.PA_Socio_Sel_Listado", c, i, m, ProducerModels.Summary.class);
    }

    @Override
    public PersistenceResult<ProducerModels.Detail> get(GetProducer c, SessionIdentity i, RequestMetadata m) {
        return one("org.PA_Socio_Sel_DetalleCompleto", c, i, m, ProducerModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CreateProducer c, SessionIdentity i, RequestMetadata m) {
        return create("org.PA_Socio_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> update(UpdateProducer c, SessionIdentity i, RequestMetadata m) {
        return mutate("org.PA_Socio_Upd_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> retire(RetireProducer c, SessionIdentity i, RequestMetadata m) {
        return mutate("org.PA_Socio_Del_Registro", c, i, m);
    }

}
