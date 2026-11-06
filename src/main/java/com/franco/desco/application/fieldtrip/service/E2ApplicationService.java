package com.franco.desco.application.fieldtrip.service;

import com.franco.desco.application.fieldtrip.E2Commands;
import com.franco.desco.application.fieldtrip.port.in.E2UseCase;
import com.franco.desco.application.fieldtrip.port.out.E2PersistencePort;
import com.franco.desco.application.shared.*;
import com.franco.desco.domain.fieldtrip.E2Models;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashSet;
import com.franco.desco.application.fieldtrip.document.E2DocumentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

@Service
public final class E2ApplicationService implements E2UseCase {
    private static final Logger log=LoggerFactory.getLogger(E2ApplicationService.class);
    private final E2PersistencePort persistence;
    private final E2DocumentService documents;

    public E2ApplicationService(E2PersistencePort persistence,E2DocumentService documents) {
        this.persistence = persistence;
        this.documents = documents;
    }

    private void registrarWordSiCorresponde(AppResult<E2Models.Operation> outcome,
            Long uot,SessionIdentity identity) {
        if(!outcome.exitoso()||outcome.datos()==null||
                !"SOLICITADA".equals(outcome.datos().estado()))return;
        try {
            var word=documents.generar(uot,outcome.datos().salidaId(),identity);
            if(!word.exitoso())log.warn("Solicitud {} enviada; Word pendiente: {}",
                    outcome.datos().salidaId(),word.codigo());
        }catch(Exception ex){
            // La transición SQL ya se confirmó: no devolver un falso error de solicitud.
            // El endpoint idempotente de generación permite reintentar sin duplicar el Word.
            log.warn("Solicitud {} enviada; Word pendiente de reintento",
                    outcome.datos().salidaId(),ex);
        }
    }

    @Override public AppResult<E2Models.ListResult> listar(E2Commands.Listar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.ListResult> error=context(c.uotId(),c.convenioId(),null);
        if(error!=null)return error;
        if(c.pagina()==null||c.pagina()<1||c.tamano()==null||c.tamano()<1||c.tamano()>100)
            return error("E2_PAGINACION_INVALIDA","Revise la paginación solicitada.");
        return ok(persistence.listar(c,i,m));
    }
    @Override public AppResult<E2Models.Catalogs> catalogos(E2Commands.Catalogos c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Catalogs> error=context(c.uotId(),c.convenioId(),null);
        return error!=null?error:ok(persistence.catalogos(c,i,m));
    }
    @Override public AppResult<E2Models.Detail> ver(E2Commands.Ver c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Detail> error=context(c.uotId(),c.convenioId(),c.salidaId());
        return error!=null?error:ok(persistence.ver(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> solicitar(E2Commands.Solicitar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),null);
        if(error!=null)return error;
        var d=c.datos();
        if(d==null||blank(d.nombre())||d.motivoSalidaId()==null||d.fechaInicioPrevista()==null
                ||(!Boolean.TRUE.equals(d.borrador())&&(d.fechaFinPrevista()==null||empty(d.destinos())||!validDestinations(d.destinos()))))
            return error("E2_SOLICITUD_INCOMPLETA","Complete nombre, motivo, inicio y actividad de cada destino.");
        if(d.fechaFinPrevista()!=null&&!d.fechaFinPrevista().isAfter(d.fechaInicioPrevista()))
            return error("E2_FECHAS_INVALIDAS","El fin previsto no puede ser anterior al inicio.");
        if(!validResources(d.bienes())||!uniqueParticipants(d.participantes()))
            return error("E2_RECURSOS_INVALIDOS","Revise recursos, cantidades y participantes repetidos.");
        var outcome=ok(persistence.solicitar(c,i,m));
        registrarWordSiCorresponde(outcome,c.uotId(),i);
        return outcome;
    }
    @Override public AppResult<E2Models.Operation> corregir(E2Commands.Corregir c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        var d=c.datos();
        if(d==null||blank(d.nombre())||d.fechaInicioPrevista()==null||!validResources(d.bienes())
                ||!uniqueParticipants(d.participantes()))
            return error("E2_CORRECCION_INVALIDA","Revise los datos de la solicitud.");
        // Los borradores pueden guardarse incompletos; el PA valida destinos y actividades al enviar.
        if(!Boolean.FALSE.equals(d.enviar())&&(d.fechaFinPrevista()==null||empty(d.destinos())||!validDestinations(d.destinos())))
            return error("E2_DESTINOS_INVALIDOS","Indique la actividad prevista para cada destino.");
        if(d.fechaFinPrevista()!=null&&!d.fechaFinPrevista().isAfter(d.fechaInicioPrevista()))
            return error("E2_FECHAS_INVALIDAS","El fin previsto no puede ser anterior al inicio.");
        var outcome=ok(persistence.corregir(c,i,m));
        registrarWordSiCorresponde(outcome,c.uotId(),i);
        return outcome;
    }
    @Override public AppResult<E2Models.Operation> decidir(E2Commands.Decidir c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.datos()==null||!("APROBADA".equals(c.datos().decision())||"OBSERVADA".equals(c.datos().decision())||"RECHAZADA".equals(c.datos().decision()))
                ||(!"APROBADA".equals(c.datos().decision())&&blank(c.datos().motivo())))
            return error("E2_DECISION_INVALIDA","Indique una decisión válida y el motivo cuando corresponda.");
        return ok(persistence.decidir(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> entregar(E2Commands.Entregar c, SessionIdentity i, RequestMetadata m) {return operation(c.uotId(),c.convenioId(),c.salidaId(),persistence.entregar(c,i,m));}
    @Override public AppResult<E2Models.Operation> iniciar(E2Commands.Iniciar c, SessionIdentity i, RequestMetadata m) {return operation(c.uotId(),c.convenioId(),c.salidaId(),persistence.iniciar(c,i,m));}
    @Override public AppResult<E2Models.Operation> visitar(E2Commands.Visitar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        var d=c.datos();
        if(d==null||d.destinoId()==null||d.destinoId()<1||d.tipoVisitaId()==null||d.tipoVisitaId()<1)
            return error("E2_VISITA_INVALIDA","Seleccione destino y tipo de visita.");
        boolean oneCoordinate=d.latitud()==null ^ d.longitud()==null;
        if(oneCoordinate||d.latitud()!=null&&(!Boolean.TRUE.equals(d.ubicacionAutorizada())
                ||d.latitud().compareTo(BigDecimal.valueOf(-90))<0||d.latitud().compareTo(BigDecimal.valueOf(90))>0
                ||d.longitud().compareTo(BigDecimal.valueOf(-180))<0||d.longitud().compareTo(BigDecimal.valueOf(180))>0))
            return error("E2_UBICACION_INVALIDA","La ubicación requiere autorización y coordenadas válidas.");
        return ok(persistence.visitar(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> finalizarVisita(E2Commands.FinalizarVisita c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.visitaId()==null||c.visitaId()<1||c.datos()==null||blank(c.datos().resumen()))
            return error("E2_VISITA_CIERRE_INVALIDO","Indique la visita y qué se realizó.");
        return ok(persistence.finalizarVisita(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> retornar(E2Commands.Retornar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.datos()==null||blank(c.datos().observacionGeneral())||c.datos().bienes()==null)
            return error("E2_RETORNO_INVALIDO","Registre la observación general y el estado de los recursos.");
        return ok(persistence.retornar(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> inspeccionar(E2Commands.Inspeccionar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.datos()==null||c.datos().bienes()==null)return error("E2_INSPECCION_INVALIDA","Indique el resultado físico de cada recurso.");
        return ok(persistence.inspeccionar(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> regularizarFin(E2Commands.RegularizarFin c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        return c.fechaFinPrevista()==null?error("E2_FECHA_FIN_INVALIDA","Indique la fecha final prevista."):ok(persistence.regularizarFin(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> cerrar(E2Commands.Cerrar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.datos()!=null&&Boolean.TRUE.equals(c.datos().autorizarPendientes())&&blank(c.datos().motivoExcepcion()))
            return error("E2_EXCEPCION_SIN_MOTIVO","La excepción de cierre requiere un motivo.");
        return ok(persistence.cerrar(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> vincularDestino(E2Commands.VincularDestino c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        if(c.destinoId()==null||c.destinoId()<1||c.predioId()==null||c.predioId()<1)return error("E2_DESTINO_INVALIDO","Seleccione destino y predio.");
        return ok(persistence.vincularDestino(c,i,m));
    }
    @Override public AppResult<E2Models.Operation> cancelar(E2Commands.Cancelar c, SessionIdentity i, RequestMetadata m) {
        AppResult<E2Models.Operation> error=context(c.uotId(),c.convenioId(),c.salidaId());
        if(error!=null)return error;
        // Un borrador se elimina sin motivo. Para solicitudes enviadas, el PA E2
        // exige el motivo de cancelación según el estado real bloqueado en SQL.
        return ok(persistence.cancelar(c,i,m));
    }

    private AppResult<E2Models.Operation> operation(Long uot,Long convenio,Long salida,PersistenceResult<E2Models.Operation> result){
        AppResult<E2Models.Operation> error=context(uot,convenio,salida);return error!=null?error:ok(result);
    }
    private <T> AppResult<T> ok(PersistenceResult<T> result){return ApplicationResults.ok(result,"SALIDA_E2_OK","SALIDA_E2_ERROR",AppStatus.BAD_REQUEST);}
    private <T> AppResult<T> context(Long uot,Long convenio,Long salida){
        if(uot==null||uot<1||convenio!=null&&convenio<1||salida!=null&&salida<1)
            return error("E2_CONTEXTO_INVALIDO","Seleccione una UOT, convenio y salida válidos.");
        return null;
    }
    private static <T> AppResult<T> error(String code,String message){return AppResult.error(AppStatus.BAD_REQUEST,code,message);}
    private static boolean blank(String value){return value==null||value.isBlank();}
    private static boolean empty(List<?> values){return values==null||values.isEmpty();}
    private static boolean validDestinations(List<E2Commands.Destino> destinations){
        if(destinations==null||destinations.isEmpty())return false;
        for(var destination:destinations){
            if(destination==null||destination.predioId()==null||destination.predioId()<1
                    ||blank(destination.actividadPrevista())||destination.actividadPrevista().length()>400)return false;
        }
        return true;
    }
    private static boolean validResources(List<E2Commands.Recurso> resources){
        if(resources==null)return true;
        var keys=new HashSet<String>();
        for(var r:resources){
            if(r==null||(r.bienId()==null)==(r.suministroId()==null)||r.cantidad()==null||r.cantidad().signum()<=0)return false;
            if(r.bienId()!=null&&r.cantidad().compareTo(BigDecimal.ONE)!=0)return false;
            if(!keys.add((r.bienId()!=null?"B":"S")+(r.bienId()!=null?r.bienId():r.suministroId())))return false;
        }
        return true;
    }
    private static boolean uniqueParticipants(List<E2Commands.Participante> participants){
        if(participants==null)return true;
        var ids=new HashSet<Long>();
        for(var p:participants)if(p==null||p.empleadoId()==null||p.empleadoId()<1||!ids.add(p.empleadoId()))return false;
        return true;
    }
}
