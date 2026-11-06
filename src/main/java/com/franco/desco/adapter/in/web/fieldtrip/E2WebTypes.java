package com.franco.desco.adapter.in.web.fieldtrip;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class E2WebTypes {
    private E2WebTypes() {}

    @Schema(name="E2DestinoRequest")
    public record DestinoRequest(@Positive Long predioId,@Size(max=250) String referencia,
                                 @Size(max=400) String actividadPrevista){
        @AssertTrue(message="Seleccione un predio registrado") @Schema(hidden=true)
        public boolean isValido(){return predioId!=null&&predioId>0;}
    }
    @Schema(name="E2BienRequest")
    public record BienRequest(@Positive Long bienId,@Positive Long suministroId,
                              @DecimalMin(value="0.001") BigDecimal cantidad){
        @AssertTrue(message="Seleccione un activo o un consumible, no ambos") @Schema(hidden=true)
        public boolean isValido(){return (bienId==null)!=(suministroId==null)&&cantidad!=null&&cantidad.signum()>0
                &&(bienId==null||cantidad.compareTo(BigDecimal.ONE)==0);}
    }
    @Schema(name="E2ParticipanteRequest")
    public record ParticipanteRequest(@NotNull @Positive Long empleadoId,@Size(max=120) String funcion){}
    @Schema(name="E2SolicitudRequest")
    public record SolicitudRequest(@NotBlank @Size(max=180) String nombre,@NotNull @Positive Integer motivoSalidaId,
          @NotNull Instant fechaInicioPrevista,Instant fechaFinPrevista,@Size(max=400) String descripcion,
          List<@Valid DestinoRequest> destinos,List<@Valid BienRequest> bienes,
          List<@Valid ParticipanteRequest> participantes,Boolean borrador){
        @AssertTrue(message="Agregue un destino para enviar la solicitud") @Schema(hidden=true)
        public boolean isDestinosValidos(){return Boolean.TRUE.equals(borrador)||destinos!=null&&!destinos.isEmpty()&&destinos.stream().allMatch(DestinoRequest::isValido);}
        @AssertTrue(message="La fecha final debe ser posterior a la inicial") @Schema(hidden=true)
        public boolean isFechasValidas(){return fechaInicioPrevista!=null&&
                (Boolean.TRUE.equals(borrador)?fechaFinPrevista==null||!fechaFinPrevista.isBefore(fechaInicioPrevista)
                 :fechaFinPrevista!=null&&fechaFinPrevista.isAfter(fechaInicioPrevista));}
    }
    @Schema(name="E2FechaFinRequest") public record FechaFinRequest(@NotNull Instant fechaFinPrevista){}
    @Schema(name="E2VincularDestinoRequest") public record VincularDestinoRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Long predioId){}
    // El motivo no es obligatorio en un BORRADOR; SQL lo exige para solicitudes enviadas.
    @Schema(name="E2CancelarRequest") public record CancelarRequest(@Size(max=1200) String motivo){}
    @Schema(name="E2DecisionRequest")
    public record DecisionRequest(@NotBlank @Pattern(regexp="APROBADA|OBSERVADA|RECHAZADA") String decision,@Size(max=1200) String motivo){
        @AssertTrue(message="Las observaciones y rechazos requieren motivo") @Schema(hidden=true)
        public boolean isMotivoValido(){return "APROBADA".equals(decision)||motivo!=null&&!motivo.isBlank();}
    }
    @Schema(name="E2CorreccionRequest")
    public record CorreccionRequest(@NotBlank @Size(max=180) String nombre,@Size(max=400) String descripcion,
          @NotNull @Positive Integer motivoSalidaId,@NotNull Instant fechaInicioPrevista,Instant fechaFinPrevista,
          List<@Valid DestinoRequest> destinos,List<@Valid BienRequest> bienes,
          List<@Valid ParticipanteRequest> participantes,Boolean enviar){
        @AssertTrue(message="Agregue un destino antes de enviar") @Schema(hidden=true)
        public boolean isDestinosValidos(){return Boolean.FALSE.equals(enviar)||destinos!=null&&!destinos.isEmpty()&&destinos.stream().allMatch(DestinoRequest::isValido);}
        @AssertTrue(message="Las fechas de la corrección no son coherentes") @Schema(hidden=true)
        public boolean isFechasValidas(){return fechaInicioPrevista!=null&&
                (Boolean.FALSE.equals(enviar)?fechaFinPrevista==null||!fechaFinPrevista.isBefore(fechaInicioPrevista)
                 :fechaFinPrevista!=null&&fechaFinPrevista.isAfter(fechaInicioPrevista));}
    }
    @Schema(name="E2VisitaRequest")
    public record VisitaRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Integer tipoVisitaId,
          @Size(max=250) String objetivo,@DecimalMin("-90") @DecimalMax("90") BigDecimal latitud,
          @DecimalMin("-180") @DecimalMax("180") BigDecimal longitud,Boolean ubicacionAutorizada){
        @AssertTrue(message="La ubicación requiere autorización y ambas coordenadas") @Schema(hidden=true)
        public boolean isUbicacionValida(){return latitud==null&&longitud==null||latitud!=null&&longitud!=null&&Boolean.TRUE.equals(ubicacionAutorizada);}
    }
    @Schema(name="E2VisitaCierreRequest")
    public record VisitaCierreRequest(@NotBlank @Size(max=600) String resumen,@Size(max=600) String recomendaciones){}
    @Schema(name="E2EstadoBienRequest")
    public record EstadoBienRequest(@NotNull @Positive Long solicitudRecursoId,
         @NotBlank @Pattern(regexp="CONFORME|DANADO|FALTANTE|CONSUMIDO") String resultado,
         @DecimalMin(value="0.0") BigDecimal cantidadDevuelta,@Size(max=500) String observacion){}
    @Schema(name="E2RetornoRequest")
    public record RetornoRequest(@NotBlank @Size(max=1500) String observacionGeneral,
             @Size(max=1200) String justificacionSinVisita,@NotNull List<@Valid EstadoBienRequest> bienes){}
    @Schema(name="E2InspeccionRequest")
    public record InspeccionRequest(@Size(max=1200) String observacion,@NotNull List<@Valid EstadoBienRequest> bienes){}
    @Schema(name="E2CierreRequest")
    public record CierreRequest(Boolean autorizarPendientes,@Size(max=1200) String motivoExcepcion){
        @AssertTrue(message="La excepción de cierre requiere motivo") @Schema(hidden=true)
        public boolean isExcepcionValida(){return !Boolean.TRUE.equals(autorizarPendientes)||motivoExcepcion!=null&&!motivoExcepcion.isBlank();}
    }

    @Schema(name="E2OperacionResponse") public record Operacion(Long salidaId,Long visitaId,String estado){}
    @Schema(name="E2OpcionResponse") public record Opcion(Long id,String nombre,String codigo){}
    @Schema(name="E2RecursoOpcionResponse")
    public record RecursoOpcion(Long id,String tipo,String nombre,String codigo,String unidad,BigDecimal disponible){}
    @Schema(name="E2CatalogosResponse")
    public record Catalogos(List<Opcion> motivos,List<Opcion> tiposVisita,List<RecursoOpcion> bienes,List<Opcion> participantes){}
    @Schema(name="E2SalidaResumenResponse")
    public record Resumen(Long salidaId,String nombre,String estado,Instant fechaSolicitud,Instant fechaFinPrevista,
                          Instant fechaInicioPrevista,Long solicitanteEmpleadoId){}
    @Schema(name="E2SalidasResponse") public record Lista(Long total,List<Resumen> items){}
    @Schema(name="E2DestinoResponse") public record Destino(Long destinoId,Long predioId,String referencia,Integer orden,String actividadPrevista){}
    @Schema(name="E2ParticipanteResponse") public record Participante(Long empleadoId,String nombre,String funcion,Boolean responsable){}
    @Schema(name="E2BienResponse")
    public record Bien(Long solicitudRecursoId,Long bienId,Long suministroId,String tipo,String codigo,String nombre,
      String unidad,BigDecimal cantidadSolicitada,BigDecimal cantidadDevueltaDeclarada,BigDecimal cantidadDevueltaValidada,
      String estado,String resultadoDeclarado,String resultadoValidado,String observacion,String observacionValidacion){}
    @Schema(name="E2VisitaResponse")
    public record Visita(Long visitaId,Long destinoId,Long predioId,Instant fechaInicio,Instant fechaFin,String estado,
                         String objetivo,String resumen,String recomendaciones,String tipoVisita){}
    @Schema(name="E2EventoResponse") public record Evento(Long eventoId,String tipo,String detalle,Long usuarioId,Instant fechaHora){}
    @Schema(name="E2SalidaDetalleResponse")
    public record Detalle(Long salidaId,String nombre,String estado,Long uotId,Long convenioId,
           Long solicitanteEmpleadoId,Instant fechaSolicitud,Integer motivoSalidaId,String descripcion,
           Instant fechaInicioPrevista,Instant fechaFinPrevista,Instant fechaInicioReal,Instant fechaFinReal,
           Instant fechaAprobacion,List<Destino> destinos,List<Participante> participantes,List<Bien> bienes,
           List<Visita> visitas,List<Evento> historial,String observacionRetorno,
           String justificacionSinVisita,String observacionInspeccion){}
}
