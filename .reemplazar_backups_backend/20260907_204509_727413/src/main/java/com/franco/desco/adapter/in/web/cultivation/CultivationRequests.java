package com.franco.desco.adapter.in.web.cultivation;
import io.swagger.v3.oas.annotations.media.Schema;import jakarta.validation.constraints.*;import java.math.BigDecimal;import java.time.LocalDate;
public final class CultivationRequests{private CultivationRequests(){}
 @Schema(name="PlotCreateRequest") public record CreatePlot(@NotNull Long predioId,@NotBlank@Size(max=50)String codigo,@NotBlank@Size(max=150)String nombre,@NotNull@Positive BigDecimal areaHa){}
 @Schema(name="PlotUpdateRequest") public record UpdatePlot(@NotNull Long predioId,@NotBlank@Size(max=50)String codigo,@NotBlank@Size(max=150)String nombre,@NotNull@Positive BigDecimal areaHa){}
 @Schema(name="CropCreateRequest") public record CreateCrop(@NotNull Long parcelaId,@NotNull Long variedadPaltaId,@NotNull LocalDate fechaInicio){}
 @Schema(name="CropUpdateRequest") public record UpdateCrop(@NotNull Long variedadPaltaId,@NotNull LocalDate fechaInicio){}
 @Schema(name="CropFinishRequest") public record FinishCrop(@NotNull LocalDate fechaFin,@NotBlank@Size(max=500)String motivo){}
}
