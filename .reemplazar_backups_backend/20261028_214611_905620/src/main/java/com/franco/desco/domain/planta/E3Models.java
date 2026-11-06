package com.franco.desco.domain.planta;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
public final class E3Models {
 private E3Models() {}
 public record Option(Long id,String nombre) {}
 public record Catalogs(List<Option> variedades,List<Option> diagnosticos,List<Option> parcelas) {}
 public record Summary(Long variedadId,String variedad,Long cantidad,Long sinEvaluar) {}
 public record Plant(Long plantaId,String codigo,String variedad,Long variedadId,String estado,Long parcelaCultivoId,Long version) {}
 public record Page(Long total,List<Plant> items,List<Summary> resumen) {}
 public record Event(Long eventoId,String tipo,String estadoAnterior,String estadoNuevo,String observacion,Long visitaId,Long usuarioId,Instant fechaHora) {}
 public record Episode(Long episodioId,String diagnostico,Long diagnosticoId,Instant inicio,Instant fin,String observacion) {}
 public record Treatment(Long tratamientoId,Long episodioId,String descripcion,String resultado,Instant fechaHora,Long visitaId) {}
 public record Production(Long produccionId,Integer anio,BigDecimal estimadoKg,BigDecimal realKg,String observacion,Instant fechaHora) {}
 public record Evidence(Long archivoId,Long eventoId,String nombre,String mimeType,String url,String tipo) {}
 public record Detail(Long plantaId,Long predioId,String codigo,String variedad,Long variedadId,String estado,LocalDate fechaPlantacion,Integer edadReferenciaAnios,Integer edadActual,Long version,Long parcelaCultivoId,List<Event> historial,List<Episode> episodios,List<Treatment> tratamientos,List<Production> producciones,List<Evidence> evidencias) {}
 public record Operation(Long plantaId,Long eventoId,String estado) {}
 public record Batch(Integer total,List<Summary> resumen) {}
}
