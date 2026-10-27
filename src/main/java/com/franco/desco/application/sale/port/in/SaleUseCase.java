package com.franco.desco.application.sale.port.in;

import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.shared.AppResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.domain.sale.SaleModels;

import java.util.List;

public interface SaleUseCase {
    AppResult<List<SaleModels.Summary>> list(SessionIdentity identity, Long uotId, String status);
    AppResult<SaleModels.Detail> get(SessionIdentity identity, Long saleId);
    AppResult<List<SaleModels.PaymentMethod>> paymentMethods(SessionIdentity identity);
    AppResult<Long> create(SessionIdentity identity, SaleCommands.Create command);
    AppResult<Long> pay(SessionIdentity identity, SaleCommands.Pay command);
    AppResult<Void> deliver(SessionIdentity identity, SaleCommands.Deliver command);
    AppResult<Void> cancel(SessionIdentity identity, SaleCommands.Cancel command);
    AppResult<Void> cancelPayment(SessionIdentity identity, SaleCommands.CancelPayment command);
    AppResult<Long> issueReceipt(SessionIdentity identity, SaleCommands.IssueReceipt command);
}
