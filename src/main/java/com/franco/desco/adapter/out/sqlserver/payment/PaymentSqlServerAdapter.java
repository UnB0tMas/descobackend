package com.franco.desco.adapter.out.sqlserver.payment;

import com.franco.desco.adapter.out.sqlserver.shared.*;
import com.franco.desco.application.payment.*;
import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.payment.port.out.PaymentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.*;
import com.franco.desco.domain.payment.*;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public final class PaymentSqlServerAdapter
        extends JsonPaAdapterSupport
        implements PaymentPersistencePort {

    public PaymentSqlServerAdapter(
            SqlServerPaExecutor executor,
            PaPayloadFactory payloads,
            DatabaseRecordMapper mapper
    ) {
        super(executor, payloads, mapper);
    }

    @Override
    public PersistenceResult<PageResult<PaymentModels.Summary>> list(ListPayments c, SessionIdentity i, RequestMetadata m) {
        return page("finanzas.PA_PagoSocio_Sel_Listado", c, i, m, PaymentModels.Summary.class);
    }

    @Override
    public PersistenceResult<PaymentModels.Detail> get(GetPayment c, SessionIdentity i, RequestMetadata m) {
        return one("finanzas.PA_PagoSocio_Sel_Detalle", c, i, m, PaymentModels.Detail.class);
    }

    @Override
    public PersistenceResult<Long> create(CreatePayment c, SessionIdentity i, RequestMetadata m) {
        return create("finanzas.PA_PagoSocio_Ins_Registro", c, i, m);
    }

    @Override
    public PersistenceResult<Void> confirm(ConfirmPayment c, SessionIdentity i, RequestMetadata m) {
        return mutate("finanzas.PA_PagoSocio_Upd_Confirmar", c, i, m);
    }

    @Override
    public PersistenceResult<Void> cancel(CancelPayment c, SessionIdentity i, RequestMetadata m) {
        return mutate("finanzas.PA_PagoSocio_Upd_Anular", c, i, m);
    }

}
