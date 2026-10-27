package com.franco.desco.adapter.in.web.sale;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class SaleRequests {
    private SaleRequests() {}

    @Schema(name = "SaleLineRequest")
    public record Line(
            @NotNull @Positive Long productoId,
            @NotNull @Positive BigDecimal cantidad
    ) {}

    @Schema(name = "SaleCreateRequest")
    public record Create(
            @NotNull @Positive Long uotId,
            @NotNull @Positive Long almacenId,
            @Positive Long clientePersonaId,
            @Positive Long clienteEmpresaId,
            @NotEmpty List<@Valid Line> detalle,
            @Schema(description = "Si es verdadero, la venta reserva stock hasta reservaHasta.")
            boolean separar,
            @Future LocalDateTime reservaHasta,
            @Size(max = 500) String observacion
    ) {
        @AssertTrue(message = "Seleccione un solo cliente para la venta.")
        public boolean clienteValido() {
            return clientePersonaId == null || clienteEmpresaId == null;
        }

        @AssertTrue(message = "Indique una fecha futura cuando la venta se registre como separación.")
        public boolean reservaValida() {
            return !separar || (reservaHasta != null && reservaHasta.isAfter(LocalDateTime.now()));
        }
    }

    @Schema(name = "SalePaymentRequest")
    public record Pay(
            @NotNull @Positive Integer metodoPagoId,
            @NotNull @Positive BigDecimal importe,
            @Size(max = 120) String numeroOperacion
    ) {}

    @Schema(name = "SaleCancelRequest")
    public record Cancel(@NotBlank @Size(max = 500) String motivo) {}

    @Schema(name = "SalePaymentCancelRequest")
    public record CancelPayment(@NotBlank @Size(max = 400) String motivo) {}

    @Schema(name = "SaleReceiptRequest")
    public record Receipt(
            @Schema(allowableValues = {"BOLETA", "FACTURA"}, example = "BOLETA")
            @NotBlank @Pattern(regexp = "BOLETA|FACTURA") String tipo,
            @NotBlank @Size(max = 10) String serie,
            @NotNull @Positive Long numero,
            @Size(max = 30) String documentoCliente,
            @Size(max = 220) String nombreCliente
    ) {}
}
