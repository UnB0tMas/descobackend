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
 @Schema(name="E3LoteRequest") public record Lote(@NotEmpty List<@Valid Fila> filas,
   @Positive Long socioId) {}
 @Schema(name="E3FichaRequest") public record Ficha(LocalDate fechaPlantacion,
   @Min(0) @Max(200) Integer edadReferenciaAnios,@Positive Long variedadId,
   @Positive Long parcelaCultivoId,@NotNull @PositiveOrZero Long version) {}
 @Schema(name="E3EstadoRequest") public record Estado(@NotBlank @Pattern(regexp="SANA|ENFERMA|MUERTA|SIN_EVALUAR") String estado,
    @Positive Long diagnosticoId,@Size(max=1000) String observacion,@Positive Long visitaId,Instant fechaHora,
    @NotNull @PositiveOrZero Long version,Boolean correccionExcepcional,@Size(max=900) String motivoCorreccion) {}
 @Schema(name="E3TratamientoRequest") public record Tratamiento(@NotNull @Positive Long catalogoTratamientoId,
    @Size(max=600) String resultado,@Positive Long visitaId,Instant fechaHora) {}
 @Schema(name="E3SeguimientoRequest") public record Seguimiento(@NotBlank @Size(max=1000) String observacion,
    @Pattern(regexp="SANITARIO|PREVENTIVO|PODA|RIEGO|FERTILIZACION|OTRO") String tipo,
    @Size(max=600) String resultado,@Positive Long visitaId,Instant fechaHora) {}
 @Schema(name="E3ProduccionRequest") public record Produccion(@NotNull @Min(2000) @Max(2200) Integer anio,
    @NotBlank @Pattern(regexp="ESTIMACION|COSECHA") String tipo,
    @DecimalMin("0.0") BigDecimal estimadoKg,@DecimalMin("0.0") BigDecimal realKg,
    LocalDate fechaEvento,@Positive Long visitaId,@Size(max=500) String observacion) {}
 @Schema(name="E3SeguimientoMasivoRequest") public record SeguimientoMasivo(
   @NotEmpty @Size(max=100) List<@NotNull @Positive Long> plantasIds,
   @NotBlank @Size(max=1000) String observacion,@NotNull @Positive Long visitaId,
   @Pattern(regexp="SANITARIO|PREVENTIVO|PODA|RIEGO|FERTILIZACION|OTRO") String tipo,
   @Size(max=600) String resultado) {}
 @Schema(name="E3ResultadoSeguimientoMasivoResponse") public record ResultadoMasivo(Integer procesadas) {}
 @Schema(name="E3MedicionMateriaSecaRequest") public record Medicion(
   @NotNull @DecimalMin("0.000") @DecimalMax("100.000") BigDecimal porcentaje,
   @NotNull @Positive Long visitaId,@Size(max=1000) String observacion,Instant fechaHora) {}
 @Schema(name="E3MedicionMateriaSecaResponse") public record MedicionItem(Long medicionId,Long plantaId,
   BigDecimal porcentaje,Long visitaId,String observacion,Instant fechaHora,Long usuarioId) {}
 @Schema(name="E3MedicionesMateriaSecaResponse") public record Mediciones(List<MedicionItem> items) {}
 @Schema(name="E3EvidenciaRequest") public record Evidencia(@NotNull @Positive Long archivoId,@Positive Long eventoId) {}
 @Schema(name="E3OpcionResponse") public record Opcion(Long id,String nombre) {}
 @Schema(name="E3TratamientoCatalogoResponse") public record TratamientoCatalogo(Long id,String nombre,Long problemaId) {}
 @Schema(name="E3CatalogosResponse") public record Catalogos(List<Opcion> variedades,List<Opcion> diagnosticos,
   List<TratamientoCatalogo> tratamientos,List<Opcion> parcelas,List<Opcion> socios) {}
 @Schema(name="E3ResumenVariedadResponse") public record Resumen(Long variedadId,String variedad,Long cantidad,Long sinEvaluar,
   Long sanas,Long enfermas,Long muertas,Long plantasConEstimacion,Long plantasConCosecha,
   BigDecimal estimadoKg,BigDecimal realKg) {}
 @Schema(name="E3PlantaResumenResponse") public record Planta(Long plantaId,String codigo,String variedad,Long variedadId,String estado,Long parcelaCultivoId,Long socioId,Long version) {}
 @Schema(name="E3ResumenParcelaResponse") public record ResumenParcela(Long parcelaCultivoId,Long variedadId,String variedad,Long cantidad,
   Long plantasConEstimacion,Long plantasConCosecha,BigDecimal estimadoKg,BigDecimal realKg) {}
 @Schema(name="E3PlantasPaginaResponse") public record Pagina(Long total,List<Planta> items,List<Resumen> resumen,
   Integer anioResumen,List<ResumenParcela> resumenParcelas) {}
 @Schema(name="E3EventoResponse") public record Evento(Long eventoId,String tipo,String estadoAnterior,String estadoNuevo,String observacion,Long visitaId,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 @Schema(name="E3EpisodioResponse") public record Episodio(Long episodioId,String diagnostico,Long diagnosticoId,Instant inicio,Instant fin,String observacion,
   Long usuarioAperturaId,String usuarioApertura,Long usuarioCierreId,String usuarioCierre) {}
 @Schema(name="E3TratamientoResponse") public record TratamientoItem(Long tratamientoId,Long episodioId,String descripcion,String resultado,Instant fechaHora,Long visitaId,
   Long catalogoTratamientoId,String catalogoTratamiento,Long usuarioId,String usuarioNombre) {}
 @Schema(name="E3ProduccionResponse") public record ProduccionItem(Long produccionId,Integer anio,String tipo,BigDecimal estimadoKg,
   BigDecimal realKg,String observacion,LocalDate fechaEvento,Long visitaId,Instant fechaHora) {}
 @Schema(name="E3ProduccionPeriodoResponse") public record ProduccionPeriodo(Integer anio,BigDecimal estimadoKg,
   BigDecimal realKg,Boolean tieneEstimacion,Boolean tieneReal) {}
 @Schema(name="E3SeguimientoResponse") public record SeguimientoItem(Long seguimientoId,Long episodioId,String tipo,
   String observacion,String resultado,Long eventoId,Long visitaId,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 @Schema(name="E3FichaHistorialResponse") public record FichaItem(Long fichaId,LocalDate fechaPlantacion,
   Integer edadReferenciaAnios,LocalDate fechaReferencia,Long version,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 @Schema(name="E3EvidenciaResponse") public record EvidenciaItem(Long archivoId,Long eventoId,String nombre,String mimeType,String url,String tipo) {}
 @Schema(name="E3PlantaDetalleResponse") public record Detalle(Long plantaId,Long predioId,String codigo,String variedad,Long variedadId,
  String estado,Long socioId,Long registradoPorUsuarioId,Instant registradoEn,
  LocalDate fechaPlantacion,Integer edadReferenciaAnios,Integer edadActual,Long version,Long parcelaCultivoId,
  List<Evento> historial,List<FichaItem> fichas,List<Episodio> episodios,List<SeguimientoItem> seguimientos,
  List<TratamientoItem> tratamientos,List<ProduccionItem> producciones,
  List<ProduccionPeriodo> produccionResumen,List<EvidenciaItem> evidencias) {}
 @Schema(name="E3EstadisticasDiaResponse") public record Dia(String fecha,Long nuevosCasos,Long recuperadas,Long bajas) {}
 @Schema(name="E3EstadisticasResponse") public record Estadisticas(String desde,String hasta,Long vivas,
  Long sanas,Long enfermas,Long muertas,Long casosPeriodo,Long tratamientosPeriodo,List<Dia> serie) {}
 @Schema(name="E3ResultadoLoteResponse") public record ResultadoLote(Integer total,List<Resumen> resumen) {}
 @Schema(name="E3OperacionResponse") public record Operacion(Long plantaId,Long eventoId,String estado) {}
}
