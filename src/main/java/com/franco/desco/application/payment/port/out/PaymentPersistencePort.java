package com.franco.desco.application.payment.port.out;

import com.franco.desco.application.payment.*;
import com.franco.desco.application.payment.PaymentCommands.*;
import com.franco.desco.application.shared.*;
import com.franco.desco.application.shared.pagination.PageResult;
import com.franco.desco.domain.payment.*;
import java.util.*;

public interface PaymentPersistencePort {
    PersistenceResult<PageResult<PaymentModels.Summary>> list(ListPayments c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<PaymentModels.Detail> get(GetPayment c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Long> create(CreatePayment c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> confirm(ConfirmPayment c, SessionIdentity i, RequestMetadata m);
    PersistenceResult<Void> cancel(CancelPayment c, SessionIdentity i, RequestMetadata m);
}
