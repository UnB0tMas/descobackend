package com.franco.desco.domain.sale;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class SaleModels {
    private SaleModels() {}

    public record Summary(Long saleId, Long uotId, String uotName, Long warehouseId, String warehouse,
                          LocalDateTime dateTime, LocalDateTime reservationUntil, String status, String currency,
                          BigDecimal total, BigDecimal paid, BigDecimal balance, String customer, Long sellerUserId) {}
    public record Line(Long detailId, Long productId, String product, BigDecimal quantity, Long priceVersionId,
                       BigDecimal unitPrice, BigDecimal unitDiscount, BigDecimal subtotal) {}
    public record Payment(Long paymentId, Integer paymentMethodId, String paymentMethod, BigDecimal amount, String currency,
                          String operationNumber, LocalDateTime dateTime, Long userId, String status) {}
    public record Receipt(String type, Long receiptId, String series, Long number, LocalDateTime issuedAt) {}
    public record Detail(Summary sale, List<Line> lines, List<Payment> payments, Receipt receipt) {}
    public record PaymentMethod(Integer id, String code, String name, boolean requiresOperationNumber) {}
    public record CustomerReference(String customerType, Long personId, Long companyId, String documentType,
                                    String documentNumber, String displayName, boolean reused) {}
    public record TechnicalEmployee(Long employeeId, String employeeCode, String fullName) {}
    public record TechnicalDeliveryCreated(Long deliveryId, Long inventoryMovementId) {}
    public record TechnicalDeliverySummary(Long deliveryId, Long uotId, String uotName, Long warehouseId,
                                           String warehouse, Long employeeId, String employee, LocalDateTime dateTime,
                                           String reason, String observation, Long inventoryMovementId,
                                           Long deliveredByUserId, String deliveredByUser) {}
}
