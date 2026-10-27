package com.franco.desco.domain.liquidation;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class LiquidationModels {
    private LiquidationModels() {}

    public record Summary(
            Long liquidacionSocioId,
            Long participacionId,
            Long campaniaVentaId,
            String campania,
            Integer version,
            Instant fechaCalculo,
            BigDecimal importeBruto,
            BigDecimal totalAjustes,
            BigDecimal totalGastos,
            BigDecimal totalBonificaciones,
            BigDecimal importeNeto,
            String moneda,
            String estadoProceso,
            BigDecimal totalPagado,
            BigDecimal saldoPendiente
    ) {}

    public record Line(
            Long liquidacionDetalleId,
            String tipo,
            Long entregaDetalleId,
            Long gastoProrrateoSocioId,
            Long ajustePrecioSocioId,
            String concepto,
            BigDecimal importe
    ) {}

    public record Payment(
            Long pagoSocioId,
            Instant fechaHora,
            BigDecimal importe,
            String medioPago,
            String numeroOperacion,
            String estadoProceso
    ) {}

    public record Detail(
            Long liquidacionSocioId,
            Long participacionId,
            Integer version,
            Instant fechaCalculo,
            BigDecimal importeBruto,
            BigDecimal totalAjustes,
            BigDecimal totalGastos,
            BigDecimal totalBonificaciones,
            BigDecimal importeNeto,
            String moneda,
            String estadoProceso,
            boolean estado,
            Long campaniaVentaId,
            String numeroDocumento,
            String socioNombre,
            BigDecimal totalPagado,
            BigDecimal saldoPendiente,
            List<Line> detalle,
            List<Payment> pagos
    ) {
        public Detail {
            detalle = detalle == null ? List.of() : List.copyOf(detalle);
            pagos = pagos == null ? List.of() : List.copyOf(pagos);
        }
    }
}
