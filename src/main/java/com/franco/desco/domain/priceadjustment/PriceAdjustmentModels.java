package com.franco.desco.domain.priceadjustment;

import java.math.BigDecimal;
import java.time.Instant;

public final class PriceAdjustmentModels {
    private PriceAdjustmentModels() {}

    public record Summary(
            Long ajustePrecioSocioId,
            Long participacionId,
            Long operativoVentaId,
            Long condicionComercialId,
            String tipoAjuste,
            BigDecimal precioOriginal,
            BigDecimal precioAplicado,
            BigDecimal montoAjuste,
            BigDecimal porcentajeAjuste,
            String motivo,
            Instant fechaHora,
            String estadoAjuste,
            String usuario
    ) {}

    public record Impact(
            Long ajustePrecioSocioId,
            Long participacionId,
            Long operativoVentaId,
            Long condicionComercialId,
            String tipoAjuste,
            BigDecimal precioOriginal,
            BigDecimal precioAplicado,
            BigDecimal montoAjuste,
            BigDecimal porcentajeAjuste,
            String motivo,
            Long usuarioId,
            Instant fechaHora,
            String estadoAjuste,
            boolean estado,
            Long campaniaVentaId,
            String campania,
            String numeroDocumento,
            String socioNombre,
            Long liquidacionesRelacionadas
    ) {}
}
