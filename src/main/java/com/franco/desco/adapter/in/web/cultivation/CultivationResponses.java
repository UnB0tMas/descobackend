package com.franco.desco.adapter.in.web.cultivation;
import io.swagger.v3.oas.annotations.media.Schema;import java.math.BigDecimal;import java.time.Instant;import java.time.LocalDate;import java.util.List;
public final class CultivationResponses{private CultivationResponses(){}
 @Schema(name="CultivationSummaryResponse") public record Summary(Long parcelaId,Long predioId,String predioCodigo,String predioNombre,String parcelaCodigo,String parcelaNombre,BigDecimal areaHa,Long ubicacionId,boolean parcelaEstado,Long parcelaCultivoId,Long variedadPaltaId,String variedad,LocalDate fechaInicio,LocalDate fechaFin,String situacionCultivo,boolean cultivoEstado){}
 public record Plot(Long parcelaId,Long predioId,String predioCodigo,String predioNombre,String codigo,String nombre,BigDecimal areaHa,boolean estado,Long ubicacionId,String distritoCodigo,Long centroPobladoId,String referencia,BigDecimal latitud,BigDecimal longitud,BigDecimal altitudM){}
 public record Crop(Long parcelaCultivoId,Long variedadPaltaId,String variedadCodigo,String variedad,LocalDate fechaInicio,LocalDate fechaFin,String situacionCultivo,boolean estado){}
 public record Census(Long censoPlantasId,Long parcelaCultivoId,LocalDate fechaCenso,Integer plantasTotales,Integer plantasProductivas,Integer plantasNoProductivas,Integer plantasNuevas,Integer plantasMuertas,Integer plantasAfectadas,String observacion,boolean estado){}
 public record Evaluation(Long evaluacionAgronomicaId,Long visitaTecnicaId,Long parcelaCultivoId,Long tipoEvaluacionId,String tipoEvaluacion,Instant fechaHora,String resultado,String observacion,boolean estado){}
 public record FileRef(Long archivoId,String nombreOriginal,String mimeType,String secureUrl,Instant fechaCarga,String categoria,String origenCaptura,Long parcelaId,Long parcelaCultivoId,Long censoPlantasId,Long evaluacionAgronomicaId){}
 @Schema(name="CultivationDetailResponse") public record Detail(Plot parcela,List<Crop> cultivos,List<Census> censos,List<Evaluation> evaluaciones,List<FileRef> archivos){}
 public record Created(Long id){}
}
