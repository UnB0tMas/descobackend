package com.franco.desco.adapter.in.web.productive;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** Contratos del seguimiento general agregado. Nunca contienen plantaId ni convenioId. */
public final class GpWebTypes {
    private GpWebTypes() {}

    @Schema(name="GpParcelaResponse")
    public record Parcela(Long parcelaId,Long predioId,String codigo,String nombre,
                          java.math.BigDecimal areaHa,Boolean estado,String distritoCodigo,Long centroPobladoId,
                          BigDecimal latitud,BigDecimal longitud) {}
    @Schema(name="GpCatalogoResponse")
    public record Catalogo(String tipo,Long id,Long padreId,String nombre,String descripcion,String codigo) {}
    @Schema(name="GpCatalogoActualizarRequest")
    public record CatalogoActualizar(@Size(max=40) String codigo,
      @Size(max=160) String nombre,@Positive Long padreId,
      @Size(max=1000) String descripcion,@NotNull Boolean estado) {}
    @Schema(name="GpCatalogoVariedadRequest")
    public record CatalogoVariedad(@NotNull @Positive Integer cultivoId,
      @NotBlank @Size(min=2,max=40) String codigo,
      @NotBlank @Size(min=2,max=120) String nombre,
      @Size(max=500) String descripcion) {}
    @Schema(name="GpVariedadSuperficie")
    public record VariedadSuperficie(@NotNull @Positive Long variedadId,
        @NotNull @DecimalMin("0.01") @Digits(integer=12,fraction=2) BigDecimal superficieM2,
        String nombre) {}
    @Schema(name="GpActividadResponse")
    public record Actividad(Long actividadId,Long parcelaId,Long predioId,String rubro,
      Integer cultivoId,Integer especieId,Long variedadId,String variedadNombre,String nombre,LocalDate fechaInicio,
      Boolean estado,String estadoProceso,Integer cantidadAproximada,Integer cantidadExacta,
      BigDecimal superficieAproximadaM2,BigDecimal superficieExactaM2,
      Long versionActualId,LocalDate fechaUltimoCenso) {}
    @Schema(name="GpCensoResponse")
    public record Censo(Long censoId,Long actividadId,Integer cantidadAproximada,Integer cantidadExacta,
      BigDecimal superficieAproximadaM2,BigDecimal superficieExactaM2,
      LocalDate fecha,String observacion,LocalDateTime fechaRegistro,Long usuarioId,
      List<RazaConteo> razas,List<VariedadSuperficie> variedades) {}
    @Schema(name="GpEventoResponse")
    public record Evento(Long eventoId,Long actividadId,String tipo,String observacion,
      LocalDateTime fechaHecho,LocalDateTime fechaRegistro,Long usuarioId,String usuarioNombre,Long respuestaAId,
      Integer problemaId,String problema,Integer tratamientoId,String tratamiento,
      Integer cantidadAfectada, Boolean afectadosAproximado, Long fotoId,List<Long> fotosIds) {}
    @Schema(name="GpActividadRevisionResponse")
    public record ActividadRevision(Long revisionId,Long actividadId,String nombreAnterior,
        String nombreNuevo,Boolean estadoAnterior,Boolean estadoNuevo,String motivo,
        Long usuarioId,LocalDateTime fechaRegistro) {}
    @Schema(name="GpRazaConteo")
    public record RazaConteo(@NotNull @Positive Integer razaId,
       Integer cantidadAproximada,@NotNull @PositiveOrZero Integer cantidadExacta,String nombre) {
       @AssertTrue(message="La raza debe tener al menos una cantidad") @Schema(hidden=true)
       public boolean isMedicionValida(){return cantidadAproximada==null && cantidadExacta!=null;}
    }
    @Schema(name="GpCatalogoRazaRequest")
    public record CatalogoRaza(@NotNull @Positive Integer especieId,
       @NotBlank @Size(min=2,max=120) String nombre,
       @Size(max=500) String descripcion) {}
    @Schema(name="GpIdResponse")
    public record Id(Long id) {}

    @Schema(name="GpParcelaAltaRequest")
    public record ParcelaAlta(@NotNull @Positive Long predioId,
        @NotBlank @Size(max=120) String nombre,
        @NotNull @DecimalMin("0.0001") @Digits(integer=6,fraction=4) BigDecimal areaHa,
        @NotBlank @Pattern(regexp="[0-9]{6}") String distritoCodigo,
        @Positive Long centroPobladoId,
        @DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitud,
        @DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitud) {
        @AssertTrue(message="Indique ambas coordenadas o ninguna") @Schema(hidden=true)
        public boolean isGeoposicionValida() { return (latitud==null)==(longitud==null); }
    }
    @Schema(name="GpParcelaEditarRequest")
    public record ParcelaEditar(@NotBlank @Size(max=120) String nombre,
        @NotNull @DecimalMin("0.0001") @Digits(integer=6,fraction=4) BigDecimal areaHa,
        @NotBlank @Pattern(regexp="[0-9]{6}") String distritoCodigo,
        @Positive Long centroPobladoId,
        @DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal latitud,
        @DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal longitud) {
        @AssertTrue(message="Indique ambas coordenadas o ninguna") @Schema(hidden=true)
        public boolean isGeoposicionValida() { return (latitud==null)==(longitud==null); }
    }
    @Schema(name="GpIncidenciaResponse")
    public record Incidencia(Long incidenciaId,Long actividadId,Integer problemaId,String problema,String estado,
      String resultado,BigDecimal afectadaM2,Integer afectadosAnimales,BigDecimal perdidaM2,Integer perdidosAnimales,
      String descripcion,LocalDateTime fechaRegistro,Long usuarioId,LocalDateTime fechaCierre,
      String descripcionCierre,Long usuarioCierreId) {}
    @Schema(name="GpIncidenciaEditarRequest")
    public record IncidenciaEditar(@NotNull @Positive Integer problemaId,
      @DecimalMin("0.01") @Digits(integer=12,fraction=2) BigDecimal afectadaM2,
      @Positive Integer afectadosAnimales,@NotBlank @Size(min=3,max=2000) String descripcion,
      @NotBlank @Size(min=3,max=1000) String motivo) {
      @AssertTrue(message="Indique una afectación correspondiente al rubro") @Schema(hidden=true)
      public boolean isAfectacionValida(){return (afectadaM2==null)!=(afectadosAnimales==null);}
    }
    @Schema(name="GpIncidenciaRevisionResponse")
    public record IncidenciaRevision(Long revisionId,Long incidenciaId,String accion,String motivo,
      Long usuarioId,LocalDateTime fechaRegistro,Integer problemaAnterior,Integer problemaNuevo,
      BigDecimal afectadaAnterior,BigDecimal afectadaNueva,Integer animalesAnteriores,Integer animalesNuevos,
      String descripcionAnterior,String descripcionNueva) {}
    @Schema(name="GpTratamientoSeguimientoResponse")
    public record TratamientoSeguimiento(Long eventoId,Long incidenciaId,Integer tratamientoId,String tratamiento,
      String descripcion,LocalDateTime fechaInicio,LocalDateTime fechaFinPrevista,LocalDateTime fechaFinReal,
      String descripcionCierre,Long usuarioId) {}
    @Schema(name="GpIncidenciaAltaRequest")
    public record IncidenciaAlta(@NotNull @Positive Integer problemaId,
      @DecimalMin("0.01") @Digits(integer=12,fraction=2) BigDecimal afectadaM2,
      @Positive Integer afectadosAnimales,@NotBlank @Size(min=3,max=2000) String descripcion) {
      @AssertTrue(message="Indique solo superficie afectada o animales afectados") @Schema(hidden=true)
      public boolean isAfectacionValida(){return (afectadaM2==null)!=(afectadosAnimales==null);}
    }
    @Schema(name="GpTratamientoAplicarRequest")
    public record TratamientoAplicar(@NotNull @Positive Long incidenciaId,
      @NotNull @Positive Integer tratamientoId,@NotBlank @Size(min=3,max=2000) String descripcion,
      LocalDateTime fechaFinPrevista) {}
    @Schema(name="GpTratamientoFinalizarRequest")
    public record TratamientoFinalizar(@NotBlank @Size(min=3,max=1000) String descripcion) {}
    @Schema(name="GpIncidenciaCerrarRequest")
    public record IncidenciaCerrar(@DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal perdidaM2,
      @PositiveOrZero Integer perdidosAnimales,@NotBlank @Size(min=3,max=2000) String descripcion) {
      @AssertTrue(message="Indique perdidas en el rubro correcto") @Schema(hidden=true)
      public boolean isValida(){return (perdidaM2==null)!=(perdidosAnimales==null);}
    }
    @Schema(name="GpMotivoRequest")
    public record Motivo(@NotBlank @Size(min=3,max=1000) String motivo) {}
    @Schema(name = "GpActividadAltaRequest")
    public record ActividadAlta(@NotNull @Positive Long parcelaId,
        @NotBlank @Pattern(regexp = "CULTIVO|CRIANZA") String rubro,
        @Positive Integer cultivoId,@Positive Integer especieId,@Positive Long variedadId,
        @PositiveOrZero Integer cantidadAproximada,@PositiveOrZero Integer cantidadExacta,
        @DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal superficieAproximadaM2,
        @DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal superficieExactaM2,
        List<@Valid RazaConteo> razas,List<@Valid VariedadSuperficie> variedades) {
        @AssertTrue(message="Indique superficie exacta y, para crianzas, también cantidad exacta")
        @Schema(hidden=true)
        public boolean isValida() {
            return "CULTIVO".equals(rubro) && cultivoId!=null && especieId==null
                && (superficieExactaM2!=null && superficieExactaM2.signum()>0) && superficieAproximadaM2==null
                && cantidadAproximada==null && cantidadExacta==null && (razas==null || razas.isEmpty())
                || "CRIANZA".equals(rubro) && especieId!=null && cultivoId==null
                && (cantidadExacta!=null && cantidadExacta>0) && cantidadAproximada==null
                && superficieAproximadaM2==null && superficieExactaM2!=null && superficieExactaM2.signum()>0 && variedadId==null
                && (variedades==null || variedades.isEmpty());
        }
    }
    @Schema(name = "GpActividadEditarRequest")
    public record ActividadEditar(@Size(max=120) String nombre,@NotNull Boolean estado,
        @NotBlank @Size(min=3,max=1000) String motivo) {}
    @Schema(name = "GpCensoAltaRequest")
    public record CensoAlta(@PositiveOrZero Integer cantidadAproximada,
        @PositiveOrZero Integer cantidadExacta,
        @DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal superficieAproximadaM2,
        @DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal superficieExactaM2,
        List<@Valid RazaConteo> razas,List<@Valid VariedadSuperficie> variedades,
        @NotBlank @Size(min=3,max=1000) String observacion,
        @Positive Long versionAnteriorId) {
        @AssertTrue(message="El cultivo requiere superficie; la crianza requiere cantidad y superficie exactas") @Schema(hidden=true)
        public boolean isMedicionValida(){
            return cantidadAproximada==null && superficieAproximadaM2==null &&
                superficieExactaM2!=null && superficieExactaM2.signum()>0 &&
                (cantidadExacta==null || cantidadExacta>=0);
        }
    }
    @Schema(name = "GpEventoAltaRequest")
    public record EventoAlta(@NotBlank @Pattern(regexp = "OBSERVACION|INCIDENCIA|TRATAMIENTO|EVALUACION|RESPUESTA") String tipo,
        @Positive Integer problemaId, @Positive Integer tratamientoId, @Positive Long respuestaAId,
        @NotBlank @Size(min=3,max=2000) String observacion, LocalDateTime fechaHecho,
        @PositiveOrZero Integer cantidadAfectada, Boolean afectadosAproximado) {
        @AssertTrue(message="La cantidad afectada debe indicar si es aproximada")
        @Schema(hidden=true)
        public boolean isCantidadValida() {
            return (cantidadAfectada == null && afectadosAproximado == null) ||
                   (cantidadAfectada != null && afectadosAproximado != null);
        }
    }
    @Schema(name = "GpCatalogoCultivoRequest")
    public record CatalogoCultivo(@NotBlank @Size(max=40) String codigo,
        @NotBlank @Size(max=120) String nombre,@Size(max=500) String descripcion) {}
    @Schema(name = "GpCatalogoEspecieRequest")
    public record CatalogoEspecie(@NotBlank @Size(max=30) String codigo,
        @NotBlank @Size(max=90) String nombre,@Size(max=500) String descripcion) {}
    @Schema(name = "GpCatalogoProblemaRequest")
    public record CatalogoProblema(@Positive Integer cultivoId,@Positive Integer especieId,@NotBlank @Size(max=160) String nombre) {}
    @Schema(name = "GpCatalogoTratamientoRequest")
    public record CatalogoTratamiento(@NotBlank @Size(max=160) String nombre,
        @Size(max=1000) String descripcion,@NotNull @Positive Integer problemaId) {}
    @Schema(name = "GpCatalogoRelacionRequest")
    public record CatalogoRelacion(@NotNull @Positive Integer problemaId,@NotNull @Positive Integer tratamientoId) {}
}
