package com.franco.desco.adapter.in.web.liquidation;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class LiquidationResponses {
    private LiquidationResponses(){}

    @Schema(name="LiquidationCreatedResponse")
    public record Created(Long liquidacionSocioId){}

    @Schema(name="LiquidationSummaryResponse")
    public record Summary(
            Long liquidacionSocioId,Long participacionId,Long campaniaVentaId,String campania,Integer version,Instant fechaCalculo,
            BigDecimal importeBruto,BigDecimal totalAjustes,BigDecimal totalGastos,BigDecimal totalBonificaciones,BigDecimal importeNeto,
            String moneda,String estadoProceso,BigDecimal totalPagado,BigDecimal saldoPendiente
    ){}

    @Schema(name="LiquidationLineResponse")
    public record Line(Long liquidacionDetalleId,String tipo,Long entregaDetalleId,Long gastoProrrateoSocioId,Long ajustePrecioSocioId,String concepto,BigDecimal importe){}

    @Schema(name="LiquidationPaymentResponse")
    public record Payment(Long pagoSocioId,Instant fechaHora,BigDecimal importe,String medioPago,String numeroOperacion,String estadoProceso){}

    @Schema(name="LiquidationDetailResponse")
    public record Detail(
            Long liquidacionSocioId,Long participacionId,Integer version,Instant fechaCalculo,BigDecimal importeBruto,BigDecimal totalAjustes,
            BigDecimal totalGastos,BigDecimal totalBonificaciones,BigDecimal importeNeto,String moneda,String estadoProceso,boolean estado,
            Long campaniaVentaId,String numeroDocumento,String socioNombre,BigDecimal totalPagado,BigDecimal saldoPendiente,
            List<Line> detalle,List<Payment> pagos
    ){}
}
