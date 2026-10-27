package com.franco.desco.application.sale;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public final class SaleCommands {
    private SaleCommands() {}
    public record Line(Long productId, BigDecimal quantity) {}
    public record Create(Long uotId, Long warehouseId, Long customerPersonId, Long customerCompanyId, UUID idempotencyKey,
                         List<Line> lines, boolean reservation, LocalDateTime reservationUntil, String observation) {}
    public record Pay(Long saleId, Integer paymentMethodId, BigDecimal amount, UUID idempotencyKey, String operationNumber) {}
    public record Deliver(Long saleId, UUID idempotencyKey) {}
    public record Cancel(Long saleId, String reason) {}
    public record CancelPayment(Long paymentId, String reason) {}
    public record IssueReceipt(Long saleId, String type, String series, Long number, String customerDocument, String customerName, UUID idempotencyKey) {}
}
