package com.franco.desco.adapter.in.web.priceadjustment;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.Instant;

public final class PriceAdjustmentResponses {
    private PriceAdjustmentResponses() {}

    @Schema(name="PriceAdjustmentCreatedResponse")
    public record Created(Long ajustePrecioSocioId) {}

    @Schema(name="PriceAdjustmentSummaryResponse")
    public record Summary(
            Long ajustePrecioSocioId, Long participacionId, Long operativoVentaId, Long condicionComercialId,
            String tipoAjuste, BigDecimal precioOriginal, BigDecimal precioAplicado, BigDecimal montoAjuste,
            BigDecimal porcentajeAjuste, String motivo, Instant fechaHora, String estadoAjuste, String usuario
    ) {}

    @Schema(name="PriceAdjustmentImpactResponse")
    public record Impact(
            Long ajustePrecioSocioId, Long participacionId, Long operativoVentaId, Long condicionComercialId,
            String tipoAjuste, BigDecimal precioOriginal, BigDecimal precioAplicado, BigDecimal montoAjuste,
            BigDecimal porcentajeAjuste, String motivo, Long usuarioId, Instant fechaHora, String estadoAjuste,
            boolean estado, Long campaniaVentaId, String campania, String numeroDocumento, String socioNombre,
            Long liquidacionesRelacionadas
    ) {}
}
