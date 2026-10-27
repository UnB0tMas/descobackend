package com.franco.desco.application.fieldtrip;
import com.franco.desco.application.shared.pagination.PageRequest;import java.time.Instant;import java.util.List;
public final class FieldTripCommands{private FieldTripCommands(){}
 public record Filter(String estadoProceso,Integer motivoSalidaId,Instant fechaDesde,Instant fechaHasta){}
 public record ListTrips(PageRequest<Filter> page){}
 public record GetTrip(Long salidaCampoId){}
 public record ParticipantInput(Long empleadoId,String funcion,boolean esResponsable){}
 public record Program(Integer motivoSalidaId,Instant fechaHoraProgramada,String descripcion,List<ParticipantInput> participantes){}
 public record Update(Long salidaCampoId,Integer motivoSalidaId,Instant fechaHoraProgramada,String descripcion,List<ParticipantInput> participantes){}
 public record Cancel(Long salidaCampoId,String motivo){}
 public record Finish(Long salidaCampoId,Instant fechaHoraRetornoReal,String motivo){}
}
