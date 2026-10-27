package com.franco.desco.application.sale.port.out;

import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.SaleModels;

import java.util.List;

public interface SalePersistencePort {
    PersistenceResult<List<SaleModels.Summary>> list(SessionIdentity identity, Long uotId, String status);
    PersistenceResult<SaleModels.Detail> get(SessionIdentity identity, Long saleId);
    PersistenceResult<List<SaleModels.PaymentMethod>> paymentMethods(SessionIdentity identity);
    PersistenceResult<Long> create(SessionIdentity identity, SaleCommands.Create command);
    PersistenceResult<Long> pay(SessionIdentity identity, SaleCommands.Pay command);
    PersistenceResult<Void> deliver(SessionIdentity identity, SaleCommands.Deliver command);
    PersistenceResult<Void> cancel(SessionIdentity identity, SaleCommands.Cancel command);
    PersistenceResult<Void> cancelPayment(SessionIdentity identity, SaleCommands.CancelPayment command);
    PersistenceResult<Long> issueReceipt(SessionIdentity identity, SaleCommands.IssueReceipt command);
    PersistenceResult<Integer> expireReservations();
}
