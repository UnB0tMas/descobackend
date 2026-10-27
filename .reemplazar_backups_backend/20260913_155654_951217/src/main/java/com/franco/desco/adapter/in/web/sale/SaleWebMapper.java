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
}
