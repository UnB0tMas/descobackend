package com.franco.desco.application.payment.port.out;

import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.payment.PaymentModels;

public interface PaymentPersistencePort {
    PersistenceResult<PageResult<PaymentModels.Summary>> list(ListPayments command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<PaymentModels.Detail> get(GetPayment command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Long> create(CreatePayment command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> confirm(ConfirmPayment command, SessionIdentity identity, RequestMetadata metadata);
    PersistenceResult<Void> cancel(CancelPayment command, SessionIdentity identity, RequestMetadata metadata);
}
