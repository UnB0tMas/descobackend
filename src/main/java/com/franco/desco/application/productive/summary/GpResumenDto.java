package com.franco.desco.application.productive.summary;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Estadísticas del expediente, sin datos derivados de ejemplo. */
@Schema(name = "GpResumenResponse")
public record GpResumenDto(
        Long mediciones,
        Long seguimientos,
        Long incidenciasAbiertas,
        List<Punto> evolucion,
        List<Tipo> tiposSeguimiento) {

    public record Punto(LocalDate fecha, BigDecimal valor) {}
    public record Tipo(String tipo, Long total) {}
}
