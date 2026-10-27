package com.franco.desco.domain.fieldtrip;
import java.math.BigDecimal;import java.time.Instant;import java.util.List;
public final class FieldTripModels{private FieldTripModels(){}
 public record Summary(Long salidaCampoId,Integer motivoSalidaId,String motivo,Instant fechaHoraProgramada,Instant fechaHoraSalidaReal,Instant fechaHoraRetornoReal,String descripcion,String estadoProceso,boolean estado,Long participantes,Long recursosProgramados){}
 public record Participant(Long salidaParticipanteId,Long empleadoId,String codigoEmpleado,String nombres,String apellidoPaterno,String apellidoMaterno,String funcion,boolean esResponsable,boolean estado){}
 public record Resource(Long recursoProgramadoId,Long bienInventarioId,String codigoPatrimonial,String bienNombre,Long suministroId,String suministroCodigo,String suministroNombre,String unidadMedida,BigDecimal cantidadProgramada,String observacion,String estado,BigDecimal cantidadEjecutada){}
 public record Asset(Long salidaBienId,Long bienInventarioId,String codigoPatrimonial,String nombre,Instant fechaHoraEntrega,Instant fechaHoraDevolucion,String estadoEntrega,String estadoDevolucion,String observacion,boolean estado){}
 public record Visit(Long visitaTecnicaId,Long salidaParticipanteId,Long predioId,String predioCodigo,String predioNombre,Instant fechaHoraInicio,Instant fechaHoraFin,String estadoProceso,boolean estado){}
 public record Detail(Summary salida,String motivoCodigo,List<Participant> participantes,List<Resource> recursos,List<Asset> bienes,List<Visit> visitas){public Detail{participantes=participantes==null?List.of():List.copyOf(participantes);recursos=recursos==null?List.of():List.copyOf(recursos);bienes=bienes==null?List.of():List.copyOf(bienes);visitas=visitas==null?List.of():List.copyOf(visitas);}}
}
