package com.franco.desco.adapter.out.sqlserver.delivery;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.delivery.*;
import com.franco.desco.application.delivery.DeliveryCommands.*;
import com.franco.desco.application.delivery.port.out.DeliveryPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.delivery.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class DeliverySqlServerAdapter
        extends JsonPaAdapterSupport
        implements DeliveryPersistencePort {

    public DeliverySqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<DeliveryModels.Summary>> list(DeliveryCommands.ListDeliveries c,SessionIdentity i,RequestMetadata m) {
        return page("comercial.PA_EntregaSocio_Sel_Listado", c, i, m, DeliveryModels.Summary.class);
    }

    @Override
    public PersistenceResult<DeliveryModels.Detail> get(DeliveryCommands.Get c,SessionIdentity i,RequestMetadata m) {
        return one("comercial.PA_EntregaSocio_Sel_DetalleCompleto", c, i, m, DeliveryModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(DeliveryCommands.Create c,SessionIdentity i,RequestMetadata m) {
        return create("comercial.PA_EntregaSocio_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> updatePreliminary(DeliveryCommands.UpdatePreliminary c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_EntregaSocio_Upd_RegistroPreliminar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> confirm(DeliveryCommands.Confirm c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_EntregaSocio_Upd_Confirmar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> annul(DeliveryCommands.Annul c,SessionIdentity i,RequestMetadata m) {
        return mutate("comercial.PA_EntregaSocio_Upd_Anular", c, i, m);
    }

}
