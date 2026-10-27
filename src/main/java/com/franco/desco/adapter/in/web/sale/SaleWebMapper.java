package com.franco.desco.adapter.in.web.sale;

import com.franco.desco.domain.sale.SaleModels;
import org.springframework.stereotype.Component;

@Component
public class SaleWebMapper {

    public SaleResponses.Summary response(SaleModels.Summary value) {
        return new SaleResponses.Summary(
                value.saleId(), value.uotId(), value.uotName(), value.warehouseId(), value.warehouse(),
                value.dateTime(), value.reservationUntil(), value.status(), value.currency(), value.total(),
                value.paid(), value.balance(), value.customer(), value.sellerUserId()
        );
    }

    public SaleResponses.Line response(SaleModels.Line value) {
        return new SaleResponses.Line(
                value.detailId(), value.productId(), value.product(), value.quantity(), value.priceVersionId(),
                value.unitPrice(), value.unitDiscount(), value.subtotal()
        );
    }

    public SaleResponses.Payment response(SaleModels.Payment value) {
        return new SaleResponses.Payment(
                value.paymentId(), value.paymentMethodId(), value.paymentMethod(), value.amount(), value.currency(),
                value.operationNumber(), value.dateTime(), value.userId(), value.status()
        );
    }

    public SaleResponses.Receipt response(SaleModels.Receipt value) {
        if (value == null) return null;
        return new SaleResponses.Receipt(
                value.type(), value.receiptId(), value.series(), value.number(), value.issuedAt()
        );
    }

    public SaleResponses.Detail response(SaleModels.Detail value) {
        return new SaleResponses.Detail(
                response(value.sale()),
                value.lines().stream().map(this::response).toList(),
                value.payments().stream().map(this::response).toList(),
                response(value.receipt())
        );
    }

    public SaleResponses.PaymentMethod response(SaleModels.PaymentMethod value) {
        return new SaleResponses.PaymentMethod(
                value.id(), value.code(), value.name(), value.requiresOperationNumber()
        );
    }

    public SaleResponses.CustomerReference response(SaleModels.CustomerReference value) {
        return new SaleResponses.CustomerReference(
                value.customerType(), value.personId(), value.companyId(), value.documentType(),
                value.documentNumber(), value.displayName(), value.reused()
        );
    }

    public SaleResponses.TechnicalEmployee response(SaleModels.TechnicalEmployee value) {
        return new SaleResponses.TechnicalEmployee(value.employeeId(), value.employeeCode(), value.fullName());
    }

    public SaleResponses.TechnicalDeliveryCreated response(SaleModels.TechnicalDeliveryCreated value) {
        return new SaleResponses.TechnicalDeliveryCreated(value.deliveryId(), value.inventoryMovementId());
    }

    public SaleResponses.TechnicalDeliverySummary response(SaleModels.TechnicalDeliverySummary value) {
        return new SaleResponses.TechnicalDeliverySummary(
                value.deliveryId(), value.uotId(), value.uotName(), value.warehouseId(), value.warehouse(),
                value.employeeId(), value.employee(), value.dateTime(), value.reason(), value.observation(),
                value.inventoryMovementId(), value.deliveredByUserId(), value.deliveredByUser()
        );
    }
}
