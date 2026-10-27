package com.franco.desco.adapter.in.web.expense;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ExpenseResponses {
    private ExpenseResponses() {}

    @Schema(name="ExpenseCreatedResponse")
    public record Created(Long gastoCampaniaId){}

    @Schema(name="ExpenseSummaryResponse")
    public record Summary(
            Long gastoCampaniaId,Long campaniaVentaId,String campania,Long operativoVentaId,String operativo,
            Short tipoGastoId,String tipoGasto,Short reglaProrrateoId,String reglaProrrateo,LocalDate fecha,
            String concepto,BigDecimal importe,String moneda,String estadoProceso,BigDecimal totalProrrateado
    ){}

    @Schema(name="ExpenseProrationResponse")
    public record Proration(Long gastoProrrateoSocioId,Long participacionId,BigDecimal importeAsignado,String numeroDocumento,String socioNombre){}

    @Schema(name="ExpenseDetailResponse")
    public record Detail(
            Long gastoCampaniaId,Long campaniaVentaId,Long operativoVentaId,Short tipoGastoId,String tipoGasto,
            Short reglaProrrateoId,String reglaProrrateo,LocalDate fecha,String concepto,BigDecimal importe,
            String moneda,String estadoProceso,boolean estado,List<Proration> prorrateo
    ){}
}
