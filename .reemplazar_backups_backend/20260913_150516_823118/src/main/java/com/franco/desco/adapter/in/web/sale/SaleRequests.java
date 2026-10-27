package com.franco.desco.adapter.in.web.sale;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class SaleRequests {
    private SaleRequests() {}
    public record Line(@NotNull @Positive Long productoId,@NotNull @Positive BigDecimal cantidad) {}
    public record Create(
            @NotNull @Positive Long uotId,@NotNull @Positive Long almacenId,
            @Positive Long clientePersonaId,@Positive Long clienteEmpresaId,
            @NotEmpty List<@Valid Line> detalle,boolean separar,@Future LocalDateTime reservaHasta,@Size(max=500) String observacion
    ) {
        @AssertTrue(message="Seleccione un solo cliente para la venta.") public boolean clienteValido(){return clientePersonaId==null||clienteEmpresaId==null;}
        @AssertTrue(message="Indique una fecha futura cuando la venta se registre como separación.") public boolean reservaValida(){return !separar||(reservaHasta!=null&&reservaHasta.isAfter(LocalDateTime.now()));}
    }
    public record Pay(@NotNull @Positive Integer metodoPagoId,@NotNull @Positive BigDecimal importe,@Size(max=120) String numeroOperacion) {}
    public record Cancel(@NotBlank @Size(max=500) String motivo) {}
    public record CancelPayment(@NotBlank @Size(max=400) String motivo) {}
    public record Receipt(@NotBlank @Pattern(regexp="BOLETA|FACTURA") String tipo,@NotBlank @Size(max=10) String serie,@NotNull @Positive Long numero,
                          @Size(max=30) String documentoCliente,@Size(max=220) String nombreCliente) {}
}
