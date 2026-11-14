package com.franco.desco.domain.planta;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
public final class E3Models {
 private E3Models() {}
 public record Option(Long id,String nombre) {}
 public record TreatmentOption(Long id,String nombre,Long problemaId) {}
 public record Catalogs(List<Option> variedades,List<Option> diagnosticos,List<TreatmentOption> tratamientos,
  List<Option> parcelas,List<Option> socios) {}
 public record Summary(Long variedadId,String variedad,Long cantidad,Long sinEvaluar,
  Long sanas,Long enfermas,Long muertas,Long plantasConEstimacion,Long plantasConCosecha,
  BigDecimal estimadoKg,BigDecimal realKg) {}
 public record Plant(Long plantaId,String codigo,String variedad,Long variedadId,String estado,Long parcelaCultivoId,Long socioId,Long version) {}
 public record ParcelSummary(Long parcelaCultivoId,Long variedadId,String variedad,Long cantidad,
  Long plantasConEstimacion,Long plantasConCosecha,BigDecimal estimadoKg,BigDecimal realKg) {}
 public record Page(Long total,List<Plant> items,List<Summary> resumen,Integer anioResumen,List<ParcelSummary> resumenParcelas) {}
 public record Event(Long eventoId,String tipo,String estadoAnterior,String estadoNuevo,String observacion,Long visitaId,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 public record Episode(Long episodioId,String diagnostico,Long diagnosticoId,Instant inicio,Instant fin,String observacion,
  Long usuarioAperturaId,String usuarioApertura,Long usuarioCierreId,String usuarioCierre) {}
 public record Treatment(Long tratamientoId,Long episodioId,String descripcion,String resultado,Instant fechaHora,Long visitaId,
  Long catalogoTratamientoId,String catalogoTratamiento,Long usuarioId,String usuarioNombre) {}
 public record Production(Long produccionId,Integer anio,String tipo,BigDecimal estimadoKg,BigDecimal realKg,
   String observacion,LocalDate fechaEvento,Long visitaId,Instant fechaHora) {}
 public record ProductionPeriod(Integer anio,BigDecimal estimadoKg,BigDecimal realKg,
   Boolean tieneEstimacion,Boolean tieneReal) {}
 public record FollowUp(Long seguimientoId,Long episodioId,String tipo,String observacion,
   String resultado,Long eventoId,Long visitaId,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 public record PlantFile(Long fichaId,LocalDate fechaPlantacion,Integer edadReferenciaAnios,
   LocalDate fechaReferencia,Long version,Long usuarioId,String usuarioNombre,Instant fechaHora) {}
 public record Evidence(Long archivoId,Long eventoId,String nombre,String mimeType,String url,String tipo) {}
 public record Detail(Long plantaId,Long predioId,String codigo,String variedad,Long variedadId,
   String estado,Long socioId,Long registradoPorUsuarioId,Instant registradoEn,
   LocalDate fechaPlantacion,Integer edadReferenciaAnios,Integer edadActual,Long version,Long parcelaCultivoId,
   List<Event> historial,List<PlantFile> fichas,List<Episode> episodios,List<FollowUp> seguimientos,
   List<Treatment> tratamientos,List<Production> producciones,List<ProductionPeriod> produccionResumen,
   List<Evidence> evidencias) {}
 public record StatsDay(String fecha,Long nuevosCasos,Long recuperadas,Long bajas) {}
 public record Stats(String desde,String hasta,Long vivas,Long sanas,Long enfermas,Long muertas,
  Long casosPeriodo,Long tratamientosPeriodo,List<StatsDay> serie) {}
 public record Operation(Long plantaId,Long eventoId,String estado) {}
 public record Batch(Integer total,List<Summary> resumen) {}
 public record BatchFollowUp(Integer procesadas) {}
 public record Measurement(Long medicionId,Long plantaId,BigDecimal porcentaje,Long visitaId,
                           String observacion,Instant fechaHora,Long usuarioId) {}
 public record Measurements(List<Measurement> items) {}
}
