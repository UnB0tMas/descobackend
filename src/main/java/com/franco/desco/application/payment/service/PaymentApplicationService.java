package com.franco.desco.application.payment.service;

import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.payment.port.in.PaymentUseCase;
import com.franco.desco.application.payment.port.out.PaymentPersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.payment.PaymentModels;

public final class PaymentApplicationService implements PaymentUseCase {
    private final PaymentPersistencePort persistence;
    public PaymentApplicationService(PaymentPersistencePort persistence) { this.persistence = persistence; }

    public AppResult<PageResult<PaymentModels.Summary>> list(ListPayments c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.list(c,i,m),"PAGOS_LISTADOS","PAGOS_NO_LISTADOS",AppStatus.BAD_REQUEST);
    }
    public AppResult<PaymentModels.Detail> get(GetPayment c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.get(c,i,m),"PAGO_OBTENIDO","PAGO_NO_DISPONIBLE",AppStatus.NOT_FOUND);
    }
    public AppResult<Long> create(CreatePayment c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.created(persistence.create(c,i,m),"PAGO_REGISTRADO","PAGO_NO_REGISTRADO");
    }
    public AppResult<Void> confirm(ConfirmPayment c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.confirm(c,i,m),"PAGO_CONFIRMADO","PAGO_NO_CONFIRMADO",AppStatus.BAD_REQUEST);
    }
    public AppResult<Void> cancel(CancelPayment c, SessionIdentity i, RequestMetadata m) {
        return ApplicationResults.ok(persistence.cancel(c,i,m),"PAGO_ANULADO","PAGO_NO_ANULADO",AppStatus.BAD_REQUEST);
    }
}
