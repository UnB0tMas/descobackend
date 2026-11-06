package com.franco.desco.adapter.in.web.fieldtrip;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.domain.fieldtrip.E2Models;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public final class E2WebMapper {
    public E2Commands.SolicitudDatos solicitud(E2WebTypes.SolicitudRequest q){return new E2Commands.SolicitudDatos(q.nombre(),q.motivoSalidaId(),q.fechaInicioPrevista(),q.fechaFinPrevista(),q.descripcion(),destinos(q.destinos()),recursos(q.bienes()),participantes(q.participantes()),q.borrador());}
    public E2Commands.CorreccionDatos correccion(E2WebTypes.CorreccionRequest q){return new E2Commands.CorreccionDatos(q.nombre(),q.descripcion(),q.motivoSalidaId(),q.fechaInicioPrevista(),q.fechaFinPrevista(),destinos(q.destinos()),recursos(q.bienes()),participantes(q.participantes()),q.enviar());}
    public E2Commands.DecisionDatos decision(E2WebTypes.DecisionRequest q){return new E2Commands.DecisionDatos(q.decision(),q.motivo());}
    public E2Commands.VisitaDatos visita(E2WebTypes.VisitaRequest q){return new E2Commands.VisitaDatos(q.destinoId(),q.tipoVisitaId(),q.objetivo(),q.latitud(),q.longitud(),q.ubicacionAutorizada());}
    public E2Commands.VisitaCierreDatos visitaCierre(E2WebTypes.VisitaCierreRequest q){return new E2Commands.VisitaCierreDatos(q.resumen(),q.recomendaciones());}
    public E2Commands.RetornoDatos retorno(E2WebTypes.RetornoRequest q){return new E2Commands.RetornoDatos(q.observacionGeneral(),q.justificacionSinVisita(),estados(q.bienes()));}
    public E2Commands.InspeccionDatos inspeccion(E2WebTypes.InspeccionRequest q){return new E2Commands.InspeccionDatos(q.observacion(),estados(q.bienes()));}
    public E2Commands.CierreDatos cierre(E2WebTypes.CierreRequest q){return q==null?new E2Commands.CierreDatos(false,null):new E2Commands.CierreDatos(q.autorizarPendientes(),q.motivoExcepcion());}

    private List<E2Commands.Destino> destinos(List<E2WebTypes.DestinoRequest> values){return values==null?List.of():values.stream().map(x->new E2Commands.Destino(x.predioId(),x.referencia(),x.actividadPrevista())).toList();}
    private List<E2Commands.Recurso> recursos(List<E2WebTypes.BienRequest> values){return values==null?List.of():values.stream().map(x->new E2Commands.Recurso(x.bienId(),x.suministroId(),x.cantidad())).toList();}
    private List<E2Commands.Participante> participantes(List<E2WebTypes.ParticipanteRequest> values){return values==null?List.of():values.stream().map(x->new E2Commands.Participante(x.empleadoId(),x.funcion())).toList();}
    private List<E2Commands.EstadoRecurso> estados(List<E2WebTypes.EstadoBienRequest> values){return values==null?List.of():values.stream().map(x->new E2Commands.EstadoRecurso(x.solicitudRecursoId(),x.resultado(),x.cantidadDevuelta(),x.observacion())).toList();}

    public E2WebTypes.Operacion response(E2Models.Operation x){return new E2WebTypes.Operacion(x.salidaId(),x.visitaId(),x.estado());}
    public E2WebTypes.Lista response(E2Models.ListResult x){return new E2WebTypes.Lista(x.total(),safe(x.items()).stream().map(this::response).toList());}
    private E2WebTypes.Resumen response(E2Models.Row x){return new E2WebTypes.Resumen(x.salidaId(),x.nombre(),x.estado(),x.fechaSolicitud(),x.fechaFinPrevista(),x.fechaInicioPrevista(),x.solicitanteEmpleadoId());}
    public E2WebTypes.Catalogos response(E2Models.Catalogs x){return new E2WebTypes.Catalogos(
            safe(x.motivos()).stream().map(this::response).toList(),safe(x.tiposVisita()).stream().map(this::response).toList(),
            safe(x.bienes()).stream().map(this::response).toList(),safe(x.participantes()).stream().map(this::response).toList());}
    private E2WebTypes.Opcion response(E2Models.Option x){return new E2WebTypes.Opcion(x.id(),x.nombre(),x.codigo());}
    private E2WebTypes.RecursoOpcion response(E2Models.ResourceOption x){return new E2WebTypes.RecursoOpcion(x.id(),x.tipo(),x.nombre(),x.codigo(),x.unidad(),x.disponible());}
    public E2WebTypes.Detalle response(E2Models.Detail x){return new E2WebTypes.Detalle(x.salidaId(),x.nombre(),x.estado(),x.uotId(),x.convenioId(),x.solicitanteEmpleadoId(),x.fechaSolicitud(),x.motivoSalidaId(),x.descripcion(),x.fechaInicioPrevista(),x.fechaFinPrevista(),x.fechaInicioReal(),x.fechaFinReal(),x.fechaAprobacion(),
            safe(x.destinos()).stream().map(d->new E2WebTypes.Destino(d.destinoId(),d.predioId(),d.referencia(),d.orden(),d.actividadPrevista())).toList(),
            safe(x.participantes()).stream().map(p->new E2WebTypes.Participante(p.empleadoId(),p.nombre(),p.funcion(),p.responsable())).toList(),
            safe(x.bienes()).stream().map(b->new E2WebTypes.Bien(b.solicitudRecursoId(),b.bienId(),b.suministroId(),b.tipo(),b.codigo(),b.nombre(),b.unidad(),b.cantidadSolicitada(),b.cantidadDevueltaDeclarada(),b.cantidadDevueltaValidada(),b.estado(),b.resultadoDeclarado(),b.resultadoValidado(),b.observacion(),b.observacionValidacion())).toList(),
            safe(x.visitas()).stream().map(v->new E2WebTypes.Visita(v.visitaId(),v.destinoId(),v.predioId(),v.fechaInicio(),v.fechaFin(),v.estado(),v.objetivo(),v.resumen(),v.recomendaciones(),v.tipoVisita())).toList(),
            safe(x.historial()).stream().map(h->new E2WebTypes.Evento(h.eventoId(),h.tipo(),h.detalle(),h.usuarioId(),h.fechaHora())).toList(),
            x.observacionRetorno(),x.justificacionSinVisita(),x.observacionInspeccion());}
    private static <T> List<T> safe(List<T> values){return values==null?List.of():values;}
}
