package com.franco.desco.adapter.in.web.planta;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
public final class E3WebTypes {
 private E3WebTypes() {}
 @Schema(name="E3FilaLoteRequest") public record Fila(@NotNull @Positive Long variedadId,
   @NotNull @Min(1) @Max(1000) Integer cantidad,@Positive Long parcelaCultivoId) {}
 @Schema(name="E3LoteRequest") public record Lote(@NotEmpty List<@Valid Fila> filas) {}
 @Schema(name="E3FichaRequest") public record Ficha(LocalDate fechaPlantacion,
   @Min(0) @Max(200) Integer edadReferenciaAnios,@NotNull @PositiveOrZero Long version) {}
 @Schema(name="E3EstadoRequest") public record Estado(@NotBlank @Pattern(regexp="SANA|ENFERMA|MUERTA") String estado,
    @Positive Long diagnosticoId,@Size(max=1000) String observacion,@Positive Long visitaId,Instant fechaHora,
    @NotNull @PositiveOrZero Long version) {}
 @Schema(name="E3TratamientoRequest") public record Tratamiento(@NotBlank @Size(max=600) String descripcion,
    @Size(max=600) String resultado,@Positive Long visitaId,Instant fechaHora) {}
 @Schema(name="E3SeguimientoRequest") public record Seguimiento(@NotBlank @Size(max=1000) String observacion,
    @Positive Long visitaId,Instant fechaHora) {}
 @Schema(name="E3ProduccionRequest") public record Produccion(@NotNull @Min(2000) @Max(2200) Integer anio,
    @DecimalMin("0.0") BigDecimal estimadoKg,@DecimalMin("0.0") BigDecimal realKg,@Size(max=500) String observacion) {}
 @Schema(name="E3EvidenciaRequest") public record Evidencia(@NotNull @Positive Long archivoId,@Positive Long eventoId) {}
 @Schema(name="E3OpcionResponse") public record Opcion(Long id,String nombre) {}
 @Schema(name="E3CatalogosResponse") public record Catalogos(List<Opcion> variedades,List<Opcion> diagnosticos,List<Opcion> parcelas) {}
 @Schema(name="E3ResumenVariedadResponse") public record Resumen(Long variedadId,String variedad,Long cantidad,Long sinEvaluar) {}
 @Schema(name="E3PlantaResumenResponse") public record Planta(Long plantaId,String codigo,String variedad,Long variedadId,String estado,Long parcelaCultivoId,Long version) {}
 @Schema(name="E3PlantasPaginaResponse") public record Pagina(Long total,List<Planta> items,List<Resumen> resumen) {}
 @Schema(name="E3EventoResponse") public record Evento(Long eventoId,String tipo,String estadoAnterior,String estadoNuevo,String observacion,Long visitaId,Long usuarioId,Instant fechaHora) {}
 @Schema(name="E3EpisodioResponse") public record Episodio(Long episodioId,String diagnostico,Long diagnosticoId,Instant inicio,Instant fin,String observacion) {}
 @Schema(name="E3TratamientoResponse") public record TratamientoItem(Long tratamientoId,Long episodioId,String descripcion,String resultado,Instant fechaHora,Long visitaId) {}
 @Schema(name="E3ProduccionResponse") public record ProduccionItem(Long produccionId,Integer anio,BigDecimal estimadoKg,BigDecimal realKg,String observacion,Instant fechaHora) {}
 @Schema(name="E3EvidenciaResponse") public record EvidenciaItem(Long archivoId,Long eventoId,String nombre,String mimeType,String url,String tipo) {}
 @Schema(name="E3PlantaDetalleResponse") public record Detalle(Long plantaId,Long predioId,String codigo,String variedad,Long variedadId,
  String estado,LocalDate fechaPlantacion,Integer edadReferenciaAnios,Integer edadActual,Long version,Long parcelaCultivoId,
  List<Evento> historial,List<Episodio> episodios,List<TratamientoItem> tratamientos,List<ProduccionItem> producciones,List<EvidenciaItem> evidencias) {}
 @Schema(name="E3ResultadoLoteResponse") public record ResultadoLote(Integer total,List<Resumen> resumen) {}
 @Schema(name="E3OperacionResponse") public record Operacion(Long plantaId,Long eventoId,String estado) {}
}
