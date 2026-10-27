package com.franco.desco.application.payment.port.in;

import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.payment.PaymentModels;

public interface PaymentUseCase {
    AppResult<PageResult<PaymentModels.Summary>> list(ListPayments command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<PaymentModels.Detail> get(GetPayment command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Long> create(CreatePayment command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> confirm(ConfirmPayment command, SessionIdentity identity, RequestMetadata metadata);
    AppResult<Void> cancel(CancelPayment command, SessionIdentity identity, RequestMetadata metadata);
}
