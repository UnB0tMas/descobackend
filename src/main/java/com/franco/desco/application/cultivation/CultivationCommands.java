package com.franco.desco.application.cultivation;

import com.franco.desco.application.shared.pagination.PageRequest;
import java.math.BigDecimal;
import java.time.LocalDate;

public final class CultivationCommands {
    private CultivationCommands() {}
    public record Filter(Long predioId,Long socioId,Long variedadPaltaId,String situacionCultivo,String buscar){}
    public record ListCultivations(PageRequest<Filter> page){}
    public record GetCultivation(Long parcelaId,Long parcelaCultivoId){}
    public record CreatePlot(Long predioId,String codigo,String nombre,BigDecimal areaHa){}
    public record UpdatePlot(Long parcelaId,Long predioId,String codigo,String nombre,BigDecimal areaHa){}
    public record CreateCrop(Long parcelaId,Long variedadPaltaId,LocalDate fechaInicio){}
    public record UpdateCrop(Long parcelaCultivoId,Long variedadPaltaId,LocalDate fechaInicio){}
    public record FinishCrop(Long parcelaCultivoId,LocalDate fechaFin,String motivo){}
}
