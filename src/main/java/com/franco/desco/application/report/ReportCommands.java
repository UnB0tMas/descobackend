package com.franco.desco.application.report;

import java.time.LocalDate;

public final class ReportCommands {
    private ReportCommands() {}

    public record Filters(String reporte, LocalDate fechaDesde, LocalDate fechaHasta, Long campaniaVentaId, Long operativoVentaId, Long zonaProductivaId) {}
    public record GetData(Filters filtros) {}
    public record ExportData(Filters filtros) {}
}
