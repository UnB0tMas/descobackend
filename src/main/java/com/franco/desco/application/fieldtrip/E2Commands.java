package com.franco.desco.application.fieldtrip;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class E2Commands {
    private E2Commands() {}

    public record Listar(Long uotId, Long convenioId, String estado, Integer pagina, Integer tamano) {}
    public record Catalogos(Long uotId, Long convenioId) {}
    public record Ver(Long uotId, Long convenioId, Long salidaId) {}
    public record Solicitar(Long uotId, Long convenioId, SolicitudDatos datos) {}
    public record Corregir(Long uotId, Long convenioId, Long salidaId, CorreccionDatos datos) {}
    public record Decidir(Long uotId, Long convenioId, Long salidaId, DecisionDatos datos) {}
    public record Entregar(Long uotId, Long convenioId, Long salidaId) {}
    public record Iniciar(Long uotId, Long convenioId, Long salidaId) {}
    public record Visitar(Long uotId, Long convenioId, Long salidaId, VisitaDatos datos) {}
    public record FinalizarVisita(Long uotId, Long convenioId, Long salidaId, Long visitaId, VisitaCierreDatos datos) {}
    public record Retornar(Long uotId, Long convenioId, Long salidaId, RetornoDatos datos) {}
    public record Inspeccionar(Long uotId, Long convenioId, Long salidaId, InspeccionDatos datos) {}
    public record RegularizarFin(Long uotId, Long convenioId, Long salidaId, Instant fechaFinPrevista) {}
    public record Cerrar(Long uotId, Long convenioId, Long salidaId, CierreDatos datos) {}
    public record VincularDestino(Long uotId, Long convenioId, Long salidaId, Long destinoId, Long predioId) {}
    public record Cancelar(Long uotId, Long convenioId, Long salidaId, String motivo) {}

    public record Destino(Long predioId, String referencia, String actividadPrevista) {}
    public record Recurso(Long bienId, Long suministroId, BigDecimal cantidad) {}
    public record Participante(Long empleadoId, String funcion) {}
    public record SolicitudDatos(String nombre, Integer motivoSalidaId, Instant fechaInicioPrevista,
                                 Instant fechaFinPrevista, String descripcion, List<Destino> destinos,
                                 List<Recurso> bienes, List<Participante> participantes, Boolean borrador) {}
    public record CorreccionDatos(String nombre, String descripcion, Integer motivoSalidaId,
                                  Instant fechaInicioPrevista, Instant fechaFinPrevista,
                                  List<Destino> destinos, List<Recurso> bienes,
                                  List<Participante> participantes, Boolean enviar) {}
    public record DecisionDatos(String decision, String motivo) {}
    public record VisitaDatos(Long destinoId, Integer tipoVisitaId, String objetivo,
                              BigDecimal latitud, BigDecimal longitud, Boolean ubicacionAutorizada) {}
    public record VisitaCierreDatos(String resumen, String recomendaciones) {}
    public record EstadoRecurso(Long solicitudRecursoId, String resultado,
                                BigDecimal cantidadDevuelta, String observacion) {}
    public record RetornoDatos(String observacionGeneral, String justificacionSinVisita,
                               List<EstadoRecurso> bienes) {}
    public record InspeccionDatos(String observacion, List<EstadoRecurso> bienes) {}
    public record CierreDatos(Boolean autorizarPendientes, String motivoExcepcion) {}
}
