package com.franco.desco.adapter.in.web.planta;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class FundoProduccionWebTypes {
    private FundoProduccionWebTypes() {}

    @Schema(name="FundoProduccionGuardarRequest")
    public record Guardar(
            @NotNull @Min(2000) @Max(2200) Integer anio,
            @NotNull @PositiveOrZero Long version,
            @NotNull LocalDate fechaDesde,
            @NotNull LocalDate fechaHasta,
            @NotBlank @Pattern(regexp="DISPONIBLE|PARCIAL|NO_DISPONIBLE") String estado,
            @NotNull @DecimalMin("0.000") BigDecimal cantidadKg,
            @Size(max=400) String observacion) {
        @AssertTrue(message="Las fechas deben pertenecer al año indicado y estar ordenadas")
        @Schema(hidden=true)
        public boolean isPeriodoValido() {
            return anio != null && fechaDesde != null && fechaHasta != null &&
                    !fechaHasta.isBefore(fechaDesde) && fechaDesde.getYear() == anio && fechaHasta.getYear() == anio;
        }
        @AssertTrue(message="La cantidad debe ser positiva si hay producción, o cero si no está disponible")
        @Schema(hidden=true)
        public boolean isCantidadValida() {
            return estado != null && cantidadKg != null &&
                    ("NO_DISPONIBLE".equals(estado) ? cantidadKg.signum() == 0 : cantidadKg.signum() > 0);
        }
    }
    @Schema(name="FundoProduccionAnualResponse")
    public record Anual(Integer anio, BigDecimal estimadoPlantasKg, BigDecimal cosechaPlantasKg,
            BigDecimal entregasKg) {}
    @Schema(name="FundoProduccionDetalleResponse")
    public record Detalle(Long predioId, Integer anio, Long plantasActivas, Long plantasConEstimacion,
            Long plantasConCosecha, BigDecimal estimadoPlantasKg, BigDecimal cosechaPlantasKg,
            BigDecimal promedioCosechaHistoricaKg, BigDecimal promedioEntregasHistoricasKg,
            BigDecimal sugeridoKg, String fuenteSugerencia, String calidadEstimacion,
            String estado, BigDecimal cantidadKg, Long version, LocalDate fechaDesde, LocalDate fechaHasta,
            String observacion, String actualizadoEn, List<Anual> historial) {}
}
