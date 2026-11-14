package com.franco.desco.adapter.in.web.e5;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public final class E5WebTypes {
    private E5WebTypes() {}
    @Schema(name="E5ObservacionRequest")
    public record Observacion(@NotBlank @Size(max=500) String motivo) {}
    @Schema(name="E5RepartoCuotaRequest")
    public record RepartoCuota(@NotNull @Positive Long participacionId,
        @NotNull @DecimalMin("0.01") @Digits(integer=17,fraction=2) BigDecimal monto) {}
    @Schema(name="E5RepartoRequest")
    public record RepartoRequest(List<@Valid RepartoCuota> cuotas) {}
    @Schema(name="E5RepartoRectificacionRequest")
    public record RepartoRectificacion(@NotBlank @Size(max=500) String motivo,
        List<@Valid RepartoCuota> cuotas) {}
    @Schema(name="E5RectificacionRequest")
    public record Rectificacion(@NotBlank @Size(max=500) String motivoRectificacion) {}
    @Schema(name="E5PagoRequest")
    public record Pago(@NotNull @DecimalMin("0.01") @Digits(integer=17,fraction=2) BigDecimal importe,
        @NotBlank @Size(max=30) String medioPago,@Size(max=100) String referencia) {}
    @Schema(name="E5CierreRequest")
    public record CierreRequest(@NotBlank @Size(max=800) String observacion,
        boolean excepcionAutorizada,@Size(max=800) String motivoExcepcion) {}
    @Schema(name="E5SocioBalanceResponse")
    public record SocioBalance(Long participacionId,Long socioId,String socio,BigDecimal kilogramos,
        Long liquidacionId,Integer version,String liquidacionEstado,BigDecimal neto,BigDecimal pagado,BigDecimal saldo,BigDecimal bruto,BigDecimal ventaEfectiva,BigDecimal gastos,BigDecimal cargos,Boolean requiereRegeneracion) {}
    @Schema(name="E5VariedadBalanceResponse")
    public record VariedadBalance(Short variedadId,Long condicionId,BigDecimal kilogramos,
        BigDecimal bruto,BigDecimal efectivo) {}
    @Schema(name="E5RepartoResumenResponse")
    public record RepartoResumen(Long repartoId,String concepto,Integer version,BigDecimal importe,
        Integer vendedores,String estado) {}
    @Schema(name="E5TableroResponse")
    public record Tablero(Long campaniaId,String nombre,String estado,Boolean cerrada,Integer vendedores,
        BigDecimal kilogramos,BigDecimal bruto,BigDecimal ventaAjustada,BigDecimal netoAprobado,
        BigDecimal pagado,BigDecimal gastoComun,BigDecimal cargos,Long jabasAsignadas,Long jabasDevueltas,
        Long jabasFaltantes,List<SocioBalance> socios,List<VariedadBalance> variedades,
        List<RepartoResumen> repartos) {}
    @Schema(name="E5GastoResponse")
    public record Gasto(Long gastoId,String concepto,BigDecimal importe,String moneda,String estado,
        String fecha,Long repartoId,Integer version,String repartoEstado,Integer vendedores,String reglaCodigo) {}
    @Schema(name="E5GastosResponse")
    public record Gastos(Long campaniaId,List<Gasto> gastos) {}
    @Schema(name="E5CuotaResponse")
    public record Cuota(Long participacionId,BigDecimal monto) {}
    @Schema(name="E5RepartoResponse")
    public record Reparto(Long repartoId,Integer version,Integer vendedores,BigDecimal importe,
        String moneda,String estado,String observacion,List<Cuota> socios) {}
    @Schema(name="E5RepartosResponse")
    public record Repartos(Long gastoId,List<Reparto> repartos) {}
    @Schema(name="E5LiquidacionResumenResponse")
    public record LiquidacionResumen(Long liquidacionId,Long participacionId,Integer version,
       BigDecimal neto,String moneda,String estado,BigDecimal pagado) {}
    @Schema(name="E5LiquidacionesResponse")
    public record Liquidaciones(Long campaniaId,List<LiquidacionResumen> liquidaciones) {}
    @Schema(name="E5LineaResponse")
    public record Linea(Long detalleId,String tipo,String concepto,BigDecimal importe,
        Long entregaDetalleId,Long gastoLineaId,Long ajusteId) {}
    @Schema(name="E5PagoResponse")
    public record PagoDetalle(Long pagoId,BigDecimal importe,String medioPago,String referencia,
        String estado,String fecha) {}
    @Schema(name="E5LiquidacionResponse")
    public record Liquidacion(Long liquidacionId,Long participacionId,Integer version,String estado,
        String moneda,BigDecimal neto,BigDecimal pagado,BigDecimal saldo,BigDecimal kilogramos,
        BigDecimal bruto,BigDecimal ajustePrecio,BigDecimal ventaAjustada,BigDecimal cargos,
        BigDecimal gastos,BigDecimal descuentos,BigDecimal bonificaciones,BigDecimal redondeo,String creado,String aprobado,
        String observacion,List<Linea> detalle,List<PagoDetalle> pagos) {}
    @Schema(name="E5DiferenciaResponse")
    public record Diferencia(String codigo,String detalle) {}
    @Schema(name="E5ValidacionCierreResponse")
    public record ValidacionCierre(Long campaniaId,Integer pendientes,boolean habilitado,List<Diferencia> diferencias) {}
    @Schema(name="E5CierreResponse")
    public record Cierre(Long campaniaId,String fecha,List<Diferencia> diferencias) {}
    @Schema(name="E5CobroResponse")
    public record Cobro(Long cobroId,BigDecimal importe,String moneda,String estado,String fecha) {}
    @Schema(name="E5CobrosResponse")
    public record Cobros(Long campaniaId,BigDecimal ventaComprador,BigDecimal saldoComprador,BigDecimal cobrado,List<Cobro> movimientos) {}
}
