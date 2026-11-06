package com.franco.desco.adapter.in.web.fieldtrip;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;

public final class E2WebTypes {
    private E2WebTypes() {}
    @Schema(name="E2DestinoRequest")
    public record DestinoRequest(@Positive Long predioId, @Size(max=250) String referencia) {
        @AssertTrue(message="Indique un predio o una referencia de destino")
        @Schema(hidden=true)
        public boolean isValido() { return predioId != null || referencia != null && !referencia.isBlank(); }
    }
    @Schema(name="E2BienRequest")
    public record BienRequest(@NotNull @Positive Long bienId) {}
    @Schema(name="E2SolicitudRequest")
    public record SolicitudRequest(@NotBlank @Size(max=180) String nombre,
          @NotNull @Positive Integer motivoSalidaId, @NotNull Instant fechaInicioPrevista,
          Instant fechaFinPrevista, @Size(max=400) String descripcion,
          @NotEmpty List<@Valid DestinoRequest> destinos,
          List<@Valid BienRequest> bienes) {
        @AssertTrue(message="La fecha final debe ser posterior a la inicial") @Schema(hidden=true)
        public boolean isFechasValidas() { return fechaInicioPrevista != null &&
                   (fechaFinPrevista == null || !fechaFinPrevista.isBefore(fechaInicioPrevista)); }
    }
    @Schema(name="E2VincularDestinoRequest")
    public record VincularDestinoRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Long predioId) {}
    @Schema(name="E2CancelarRequest")
    public record CancelarRequest(@NotBlank @Size(max=1200) String motivo) {}
    @Schema(name="E2DecisionRequest")
    public record DecisionRequest(@NotBlank @Pattern(regexp="APROBADA|OBSERVADA|RECHAZADA") String decision,
              @Size(max=1200) String motivo) {
        @AssertTrue(message="Las observaciones y rechazos requieren motivo") @Schema(hidden=true)
        public boolean isMotivoValido() { return "APROBADA".equals(decision) || motivo != null && !motivo.isBlank(); }
    }
    @Schema(name="E2CorreccionRequest")
    public record CorreccionRequest(@NotBlank @Size(max=180) String nombre,@Size(max=400) String descripcion) {}
    @Schema(name="E2VisitaRequest")
    public record VisitaRequest(@NotNull @Positive Long destinoId,@NotNull @Positive Integer tipoVisitaId,
          @Size(max=250) String objetivo) {}
    @Schema(name="E2VisitaCierreRequest")
    public record VisitaCierreRequest(@NotBlank @Size(max=600) String resumen) {}
    @Schema(name="E2EstadoBienRequest")
    public record EstadoBienRequest(@NotNull @Positive Long solicitudRecursoId,
         @NotBlank @Pattern(regexp="CONFORME|DANADO|FALTANTE") String resultado,
         @Size(max=500) String observacion) {}
    @Schema(name="E2RetornoRequest")
    public record RetornoRequest(@NotBlank @Size(max=1500) String observacionGeneral,
             @NotNull List<@Valid EstadoBienRequest> bienes) {}
    @Schema(name="E2InspeccionRequest")
    public record InspeccionRequest(@Size(max=1200) String observacion,
             @NotNull List<@Valid EstadoBienRequest> bienes) {}

    @Schema(name="E2OperacionResponse")
    public record Operacion(Long salidaId,Long visitaId,String estado) {}
    @Schema(name="E2OpcionResponse")
    public record Opcion(Long id,String nombre,String codigo) {}
    @Schema(name="E2CatalogosResponse")
    public record Catalogos(List<Opcion> motivos,List<Opcion> tiposVisita,List<Opcion> bienes) {}
    @Schema(name="E2SalidaResumenResponse")
    public record Resumen(Long salidaId,String nombre,String estado,Instant fechaSolicitud,
           Instant fechaFinPrevista,Instant fechaInicioPrevista,Long solicitanteEmpleadoId) {}
    @Schema(name="E2SalidasResponse")
    public record Lista(Long total,List<Resumen> items) {}
    @Schema(name="E2DestinoResponse")
    public record Destino(Long destinoId,Long predioId,String referencia,Integer orden) {}
    @Schema(name="E2BienResponse")
    public record Bien(Long solicitudRecursoId,Long bienId,String nombre,String estado,
      String resultadoDeclarado,String resultadoValidado,String observacion) {}
    @Schema(name="E2VisitaResponse")
    public record Visita(Long visitaId,Long predioId,Instant fechaInicio,Instant fechaFin,String estado,
                         String objetivo,String resumen,String tipoVisita) {}
    @Schema(name="E2EventoResponse")
    public record Evento(Long eventoId,String tipo,String detalle,Long usuarioId,Instant fechaHora) {}
    @Schema(name="E2SalidaDetalleResponse")
    public record Detalle(Long salidaId,String nombre,String estado,Long uotId,Long convenioId,
           Long solicitanteEmpleadoId,Instant fechaSolicitud,Integer motivoSalidaId,
           String descripcion,Instant fechaInicioPrevista,Instant fechaFinPrevista,
           Instant fechaInicioReal,Instant fechaFinReal,Instant fechaAprobacion,
           List<Destino> destinos,List<Bien> bienes,List<Visita> visitas,
           List<Evento> historial,String observacionRetorno) {}
}
