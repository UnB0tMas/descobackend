package com.franco.desco.adapter.in.web.productive;

import com.franco.desco.application.shared.SessionIdentity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import java.math.BigDecimal;
import tools.jackson.databind.json.JsonMapper;
import java.util.UUID;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** Una operación por PA: sin comandos multiplexados ni SQL de escritura en Java. */
@Repository
public class GpRepository {
    private final JdbcTemplate db;
    private final JsonMapper json;
    public GpRepository(JdbcTemplate db, JsonMapper json) { this.db = db; this.json = json; }
    /** Escrituras productivas solo durante visita iniciada en una salida aprobada y en ejecución. */
    private void verificarVisita(SessionIdentity usuario,long uotId,long predioId) {
        Boolean autorizado=db.queryForObject("""
            SELECT CONVERT(BIT,CASE WHEN EXISTS (
                SELECT 1 FROM campo.SalidaE2 S
                JOIN campo.SalidaDestinoE2 D ON D.salida_campo_id=S.salida_campo_id
                JOIN campo.SalidaVisitaE2 SV ON SV.destino_id=D.destino_id
                JOIN campo.VisitaTecnica VT ON VT.visita_tecnica_id=SV.visita_tecnica_id
                JOIN campo.SalidaParticipante SP ON SP.salida_campo_id=S.salida_campo_id AND SP.estado=1
                JOIN seg.Usuario U ON U.persona_id=SP.empleado_id AND U.estado=1
                WHERE U.usuario_id=? AND S.uot_id=? AND D.predio_id=?
                  AND S.estado='EN_EJECUCION' AND VT.estado_proceso='INICIADA'
            ) THEN 1 ELSE 0 END)
            """,Boolean.class,usuario.usuarioId(),uotId,predioId);
        if (!Boolean.TRUE.equals(autorizado))
            throw new AccessDeniedException("Debe iniciar la visita al predio desde una salida aprobada.");
    }
    private long predioParcela(long uotId,long parcelaId){
        Long id=db.query("SELECT P.predio_id FROM prod.Parcela P JOIN prod.PredioAmbito A ON A.predio_id=P.predio_id AND A.uot_id=? WHERE P.parcela_id=?",
          rs->rs.next()?rs.getLong(1):null,uotId,parcelaId);
        if(id==null)throw new AccessDeniedException("Parcela no disponible en la UOT.");
        return id;
    }
    private long predioActividad(long uotId,long actividadId){
        Long id=db.query("SELECT predio_id FROM prod.GPActividad WHERE uot_id=? AND actividad_id=?",
          rs->rs.next()?rs.getLong(1):null,uotId,actividadId);
        if(id==null)throw new AccessDeniedException("Actividad no disponible en la UOT.");
        return id;
    }
    private long predioIncidencia(long uotId,long incidenciaId){
        Long id=db.query("SELECT A.predio_id FROM prod.GPIncidencia I JOIN prod.GPActividad A ON A.actividad_id=I.actividad_id WHERE A.uot_id=? AND I.incidencia_id=?",
          rs->rs.next()?rs.getLong(1):null,uotId,incidenciaId);
        if(id==null)throw new AccessDeniedException("Incidencia no disponible en la UOT.");
        return id;
    }
    private long predioEvento(long uotId,long eventoId){
        Long id=db.query("SELECT A.predio_id FROM prod.GPEvento E JOIN prod.GPActividad A ON A.actividad_id=E.actividad_id WHERE A.uot_id=? AND E.evento_id=?",
          rs->rs.next()?rs.getLong(1):null,uotId,eventoId);
        if(id==null)throw new AccessDeniedException("Evento no disponible en la UOT.");
        return id;
    }
    private String breedsJson(List<GpWebTypes.RazaConteo> values) {
        return values == null || values.isEmpty() ? null : json.writeValueAsString(values);
    }
    private String varietiesJson(List<GpWebTypes.VariedadSuperficie> values) {
        return values == null || values.isEmpty() ? null : json.writeValueAsString(values);
    }
    private static Long longValue(ResultSet r,String column)throws SQLException {
        long v=r.getLong(column);return r.wasNull()?null:v;
    }
    private static Integer intValue(ResultSet r,String column)throws SQLException {
        int v=r.getInt(column);return r.wasNull()?null:v;
    }
    private static Boolean bit(ResultSet r,String column)throws SQLException {
        boolean v=r.getBoolean(column);return r.wasNull()?null:v;
    }
    private static LocalDate date(ResultSet r,String column)throws SQLException {
        var v=r.getDate(column);return v==null?null:v.toLocalDate();
    }
    private static LocalDateTime time(ResultSet r,String column)throws SQLException {
        var v=r.getTimestamp(column);return v==null?null:v.toLocalDateTime();
    }
    public List<GpWebTypes.Parcela> parcelas(SessionIdentity s,long u,long predio){
        return db.query("EXEC prod.PA_GP_Parcela_Sel_Listado ?,?,?,?",(r,i)->new GpWebTypes.Parcela(
            longValue(r,"parcelaId"),longValue(r,"predioId"),r.getString("codigo"),
            r.getString("nombre"),r.getBigDecimal("areaHa"),bit(r,"estado"),
            r.getString("distritoCodigo"),longValue(r,"centroPobladoId"),
            r.getBigDecimal("latitud"),r.getBigDecimal("longitud")),
            s.sesionPublicaId(),s.usuarioId(),u,predio);
    }
    public Long crearParcela(SessionIdentity s,long u,GpWebTypes.ParcelaAlta q,UUID key){
        verificarVisita(s,u,q.predioId());
        return db.queryForObject("EXEC prod.PA_GP_Parcela_Ins_Registro ?,?,?,?,?,?,?,?,?,?,?",Long.class,
            s.sesionPublicaId(),s.usuarioId(),u,q.predioId(),q.nombre(),q.areaHa(),
            q.distritoCodigo(),q.centroPobladoId(),q.latitud(),q.longitud(),key);
    }
    public Long editarParcela(SessionIdentity s,long u,long id,GpWebTypes.ParcelaEditar q,UUID key){
        verificarVisita(s,u,predioParcela(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Parcela_Upd_Registro ?,?,?,?,?,?,?,?,?,?,?",Long.class,
            s.sesionPublicaId(),s.usuarioId(),u,id,q.nombre(),q.areaHa(),
            q.distritoCodigo(),q.centroPobladoId(),q.latitud(),q.longitud(),key);
    }
    public List<GpWebTypes.Catalogo> catalogos(SessionIdentity s,long u){
        return db.query("EXEC prod.PA_GP_Catalogo_Sel_Listado ?,?,?",(r,i)->new GpWebTypes.Catalogo(
            r.getString("tipo"),longValue(r,"id"),longValue(r,"padreId"),
            r.getString("nombre"),r.getString("descripcion"),r.getString("codigo")),s.sesionPublicaId(),s.usuarioId(),u);
    }
    public List<GpWebTypes.Actividad> actividades(SessionIdentity s,long u,long parcela){
        return db.query("EXEC prod.PA_GP_Actividad_Sel_Listado ?,?,?,?",(r,i)->new GpWebTypes.Actividad(
            longValue(r,"actividadId"),longValue(r,"parcelaId"),longValue(r,"predioId"),
            r.getString("rubro"),intValue(r,"cultivoId"),intValue(r,"especieId"),longValue(r,"variedadId"),r.getString("variedadNombre"),
            r.getString("nombre"),date(r,"fechaInicio"),bit(r,"estado"),r.getString("estadoProceso"),
            intValue(r,"cantidadAproximada"),intValue(r,"cantidadExacta"),
            r.getBigDecimal("superficieAproximadaM2"),r.getBigDecimal("superficieExactaM2"),
            longValue(r,"versionActualId"),date(r,"fechaUltimoCenso")),
            s.sesionPublicaId(),s.usuarioId(),u,parcela);
    }
    public Long crearActividad(SessionIdentity s,long u,GpWebTypes.ActividadAlta q,UUID key){
        verificarVisita(s,u,predioParcela(u,q.parcelaId()));
        return db.queryForObject("EXEC prod.PA_GP_Actividad_Ins_Registro ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?",Long.class,
           s.sesionPublicaId(),s.usuarioId(),u,q.parcelaId(),q.rubro(),q.cultivoId(),
           q.especieId(),q.cantidadAproximada(),q.cantidadExacta(),
           q.superficieAproximadaM2(),q.superficieExactaM2(),breedsJson(q.razas()),key,q.variedadId(),varietiesJson(q.variedades()));
    }
    public Long editarActividad(SessionIdentity s,long u,long id,GpWebTypes.ActividadEditar q,UUID key){
        verificarVisita(s,u,predioActividad(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Actividad_Upd_Registro ?,?,?,?,?,?,?,?",Long.class,
           s.sesionPublicaId(),s.usuarioId(),u,id,q.nombre(),q.estado(),q.motivo(),key);
    }
    public List<GpWebTypes.ActividadRevision> revisiones(SessionIdentity s,long u,long actividad){
        return db.query("EXEC prod.PA_GP_ActividadRevision_Sel_Historial ?,?,?,?",(r,i)->new GpWebTypes.ActividadRevision(
            longValue(r,"revisionId"),longValue(r,"actividadId"),r.getString("nombreAnterior"),
            r.getString("nombreNuevo"),bit(r,"estadoAnterior"),bit(r,"estadoNuevo"),
            r.getString("motivo"),longValue(r,"usuarioId"),time(r,"fechaRegistro")),
            s.sesionPublicaId(),s.usuarioId(),u,actividad);
    }
    public List<GpWebTypes.Censo> censos(SessionIdentity s,long u,long id){
        var rows=db.query("EXEC prod.PA_GP_Censo_Sel_Historial ?,?,?,?",(r,i)->new GpWebTypes.Censo(
           longValue(r,"censoId"),longValue(r,"actividadId"),intValue(r,"cantidadAproximada"),
           intValue(r,"cantidadExacta"),r.getBigDecimal("superficieAproximadaM2"),r.getBigDecimal("superficieExactaM2"),
           date(r,"fecha"),r.getString("observacion"),time(r,"fechaRegistro"),longValue(r,"usuarioId"),
           List.of(),List.of()),
           s.sesionPublicaId(),s.usuarioId(),u,id);
        var detail=db.query("EXEC prod.PA_GP_CensoRaza_Sel_Historial ?,?,?,?",(r,i)->
           new GpRazaRow(longValue(r,"censoId"),new GpWebTypes.RazaConteo(
             intValue(r,"razaId"),intValue(r,"cantidadAproximada"),intValue(r,"cantidadExacta"),r.getString("raza"))),
           s.sesionPublicaId(),s.usuarioId(),u,id);
        Map<Long,List<GpWebTypes.RazaConteo>> byVersion=new HashMap<>();
        for(var item:detail) byVersion.computeIfAbsent(item.censoId(),unused->new ArrayList<>()).add(item.raza());
        var crops=db.query("EXEC prod.PA_GP_CensoVariedad_Sel_Historial ?,?,?,?",(r,i)->
            new GpVariedadRow(longValue(r,"censoId"),new GpWebTypes.VariedadSuperficie(
              longValue(r,"variedadId"),r.getBigDecimal("superficieM2"),r.getString("nombre"))),
              s.sesionPublicaId(),s.usuarioId(),u,id);
        Map<Long,List<GpWebTypes.VariedadSuperficie>> byCrop=new HashMap<>();
        for(var item:crops)byCrop.computeIfAbsent(item.censoId(),unused->new ArrayList<>()).add(item.variedad());
        return rows.stream().map(c->new GpWebTypes.Censo(c.censoId(),c.actividadId(),
           c.cantidadAproximada(),c.cantidadExacta(),c.superficieAproximadaM2(),c.superficieExactaM2(),
           c.fecha(),c.observacion(),c.fechaRegistro(),c.usuarioId(),
           byVersion.getOrDefault(c.censoId(),List.of()),byCrop.getOrDefault(c.censoId(),List.of()))).toList();
    }
    private record GpRazaRow(Long censoId,GpWebTypes.RazaConteo raza) {}
    private record GpVariedadRow(Long censoId,GpWebTypes.VariedadSuperficie variedad) {}
    public Long crearCenso(SessionIdentity s,long u,long id,GpWebTypes.CensoAlta q,UUID key){
        verificarVisita(s,u,predioActividad(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Censo_Ins_Registro ?,?,?,?,?,?,?,?,?,?,?,?,?",Long.class,
           s.sesionPublicaId(),s.usuarioId(),u,id,q.cantidadAproximada(),q.cantidadExacta(),
           q.superficieAproximadaM2(),q.superficieExactaM2(),breedsJson(q.razas()),
           q.observacion(),q.versionAnteriorId(),key,varietiesJson(q.variedades()));
    }
    public List<GpWebTypes.Evento> eventos(SessionIdentity s,long u,long id){
        var events=db.query("EXEC prod.PA_GP_Evento_Sel_Historial ?,?,?,?",(r,i)->new GpWebTypes.Evento(
           longValue(r,"eventoId"),longValue(r,"actividadId"),r.getString("tipo"),
           r.getString("observacion"),time(r,"fechaHecho"),time(r,"fechaRegistro"),
           longValue(r,"usuarioId"),r.getString("usuarioNombre"),longValue(r,"respuestaAId"),intValue(r,"problemaId"),
           r.getString("problema"),intValue(r,"tratamientoId"),r.getString("tratamiento"),
           intValue(r,"cantidadAfectada"),bit(r,"afectadosAproximado"),longValue(r,"fotoId"),List.of()),
           s.sesionPublicaId(),s.usuarioId(),u,id);
        var photos=db.query("EXEC prod.PA_GP_EventoFoto_Sel_Listado ?,?,?,?",(r,i)->
            new GpPhotoRow(longValue(r,"eventoId"),longValue(r,"fotoId")),
            s.sesionPublicaId(),s.usuarioId(),u,id);
        Map<Long,List<Long>> byEvent=new HashMap<>();
        for(var p:photos)byEvent.computeIfAbsent(p.eventoId(),unused->new ArrayList<>()).add(p.fotoId());
        return events.stream().map(e->new GpWebTypes.Evento(e.eventoId(),e.actividadId(),e.tipo(),
            e.observacion(),e.fechaHecho(),e.fechaRegistro(),e.usuarioId(),e.usuarioNombre(),e.respuestaAId(),
            e.problemaId(),e.problema(),e.tratamientoId(),e.tratamiento(),e.cantidadAfectada(),
            e.afectadosAproximado(),e.fotoId(),byEvent.getOrDefault(e.eventoId(),List.of()))).toList();
    }
    private record GpPhotoRow(Long eventoId,Long fotoId) {}
    public Long crearEvento(SessionIdentity s,long u,long id,GpWebTypes.EventoAlta q,UUID key){
        verificarVisita(s,u,predioActividad(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Evento_Ins_Registro ?,?,?,?,?,?,?,?,?,?,?,?,?",Long.class,
           s.sesionPublicaId(),s.usuarioId(),u,id,q.tipo(),q.problemaId(),q.tratamientoId(),
           q.respuestaAId(),q.observacion(),q.fechaHecho(),q.cantidadAfectada(),q.afectadosAproximado(),key);
    }
    public List<GpWebTypes.Incidencia> incidencias(SessionIdentity s,long u,long actividad){
        return db.query("EXEC prod.PA_GP_Incidencia_Sel_Listado ?,?,?,?",(r,i)->new GpWebTypes.Incidencia(
            longValue(r,"incidenciaId"),longValue(r,"actividadId"),intValue(r,"problemaId"),r.getString("problema"),r.getString("estado"),
            r.getString("resultado"),r.getBigDecimal("afectadaM2"),intValue(r,"afectadosAnimales"),
            r.getBigDecimal("perdidaM2"),intValue(r,"perdidosAnimales"),r.getString("descripcion"),time(r,"fechaRegistro"),
            longValue(r,"usuarioId"),time(r,"fechaCierre"),r.getString("descripcionCierre"),longValue(r,"usuarioCierreId")),
            s.sesionPublicaId(),s.usuarioId(),u,actividad);
    }
    public List<GpWebTypes.TratamientoSeguimiento> tratamientosIncidencias(SessionIdentity s,long u,long actividad){
        return db.query("EXEC prod.PA_GP_Tratamiento_Sel_Incidencia ?,?,?,?",(r,i)->new GpWebTypes.TratamientoSeguimiento(
            longValue(r,"eventoId"),longValue(r,"incidenciaId"),intValue(r,"tratamientoId"),r.getString("tratamiento"),
            r.getString("descripcion"),time(r,"fechaInicio"),time(r,"fechaFinPrevista"),time(r,"fechaFinReal"),
            r.getString("descripcionCierre"),longValue(r,"usuarioId")),s.sesionPublicaId(),s.usuarioId(),u,actividad);
    }
    public Long crearIncidencia(SessionIdentity s,long u,long actividad,GpWebTypes.IncidenciaAlta q,UUID key){
        verificarVisita(s,u,predioActividad(u,actividad));
        return db.queryForObject("EXEC prod.PA_GP_Incidencia_Ins_Registro ?,?,?,?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,actividad,q.problemaId(),q.afectadaM2(),q.afectadosAnimales(),q.descripcion(),key);
    }
    public Long editarIncidencia(SessionIdentity s,long u,long id,GpWebTypes.IncidenciaEditar q,UUID key){
        verificarVisita(s,u,predioIncidencia(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Incidencia_Upd_Corregir ?,?,?,?,?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,id,q.problemaId(),q.afectadaM2(),q.afectadosAnimales(),
          q.descripcion(),q.motivo(),key);
    }
    public Long retirarIncidencia(SessionIdentity s,long u,long id,String motivo,UUID key){
        verificarVisita(s,u,predioIncidencia(u,id));
        return db.queryForObject("EXEC prod.PA_GP_Incidencia_Upd_Retirar ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,id,motivo,key);
    }
    public List<GpWebTypes.IncidenciaRevision> revisionesIncidencia(SessionIdentity s,long u,long id){
        return db.query("EXEC prod.PA_GP_IncidenciaRevision_Sel_Historial ?,?,?,?",(r,i)->new GpWebTypes.IncidenciaRevision(
          longValue(r,"revisionId"),longValue(r,"incidenciaId"),r.getString("accion"),r.getString("motivo"),
          longValue(r,"usuarioId"),time(r,"fechaRegistro"),intValue(r,"problemaAnterior"),intValue(r,"problemaNuevo"),
          r.getBigDecimal("afectadaAnterior"),r.getBigDecimal("afectadaNueva"),intValue(r,"animalesAnteriores"),
          intValue(r,"animalesNuevos"),r.getString("descripcionAnterior"),r.getString("descripcionNueva")),
          s.sesionPublicaId(),s.usuarioId(),u,id);
    }
    public Long aplicarTratamiento(SessionIdentity s,long u,long actividad,GpWebTypes.TratamientoAplicar q,UUID key){
        verificarVisita(s,u,predioActividad(u,actividad));
        return db.queryForObject("EXEC prod.PA_GP_Tratamiento_Ins_Incidencia ?,?,?,?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,actividad,q.incidenciaId(),q.tratamientoId(),q.descripcion(),q.fechaFinPrevista(),key);
    }
    public Long finalizarTratamiento(SessionIdentity s,long u,long evento,GpWebTypes.TratamientoFinalizar q,UUID key){
        verificarVisita(s,u,predioEvento(u,evento));
        return db.queryForObject("EXEC prod.PA_GP_Tratamiento_Upd_Finalizar ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,evento,q.descripcion(),key);
    }
    public Long cerrarIncidencia(SessionIdentity s,long u,long incidencia,GpWebTypes.IncidenciaCerrar q,UUID key){
        verificarVisita(s,u,predioIncidencia(u,incidencia));
        return db.queryForObject("EXEC prod.PA_GP_Incidencia_Upd_Cerrar ?,?,?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,incidencia,q.perdidaM2(),q.perdidosAnimales(),q.descripcion(),key);
    }
    private Long lifecycle(SessionIdentity s,long u,long id,String motivo,UUID key,String procedimiento){
        return db.queryForObject("EXEC prod."+procedimiento+" ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,id,motivo,key);
    }
    public Long finalizarActividad(SessionIdentity s,long u,long id,String motivo,UUID key){
        verificarVisita(s,u,predioActividad(u,id));
        return lifecycle(s,u,id,motivo,key,"PA_GP_Actividad_Upd_Finalizar");
    }
    public Long eliminarActividad(SessionIdentity s,long u,long id,String motivo,UUID key){
        verificarVisita(s,u,predioActividad(u,id));
        return lifecycle(s,u,id,motivo,key,"PA_GP_Actividad_Upd_Eliminar");
    }
    public Long eliminarParcela(SessionIdentity s,long u,long id,String motivo,UUID key){
        verificarVisita(s,u,predioParcela(u,id));
        return lifecycle(s,u,id,motivo,key,"PA_GP_Parcela_Upd_Eliminar");
    }
    public Long eliminarPredio(SessionIdentity s,long u,long id,String motivo,UUID key){
        verificarVisita(s,u,id);
        return lifecycle(s,u,id,motivo,key,"PA_GP_Predio_Upd_Eliminar");
    }
    public Long crearCultivo(SessionIdentity s,long u,GpWebTypes.CatalogoCultivo q){
        return db.queryForObject("EXEC prod.PA_GP_Cultivo_Ins_Catalogo ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.codigo(),q.nombre(),q.descripcion());
    }
    public Long crearEspecie(SessionIdentity s,long u,GpWebTypes.CatalogoEspecie q){
        return db.queryForObject("EXEC prod.PA_GP_Especie_Ins_Catalogo ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.codigo(),q.nombre(),q.descripcion());
    }
    public Long crearRaza(SessionIdentity s,long u,GpWebTypes.CatalogoRaza q){
        return db.queryForObject("EXEC prod.PA_GP_Raza_Ins_Catalogo ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.especieId(),q.nombre(),q.descripcion());
    }
    public Long crearProblema(SessionIdentity s,long u,GpWebTypes.CatalogoProblema q){
        return db.queryForObject("EXEC prod.PA_GP_Problema_Ins_Catalogo ?,?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.cultivoId(),q.especieId(),q.nombre());
    }
    /** La creación desde una enfermedad y su asociación son indivisibles. */
    @Transactional(rollbackFor = Exception.class)
    public Long crearTratamiento(SessionIdentity s,long u,GpWebTypes.CatalogoTratamiento q){
        Long id = db.queryForObject("EXEC prod.PA_GP_Tratamiento_Ins_Catalogo ?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.nombre(),q.descripcion());
        if (id == null) throw new IllegalStateException("No se obtuvo el identificador del tratamiento.");
        // La relación se crea siempre en la misma transacción.
        asociarTratamiento(s,u,new GpWebTypes.CatalogoRelacion(q.problemaId(),Math.toIntExact(id)));
        return id;
    }
    public Long asociarTratamiento(SessionIdentity s,long u,GpWebTypes.CatalogoRelacion q){
        return db.queryForObject("EXEC prod.PA_GP_Tratamiento_Ins_Asociacion ?,?,?,?,?",Long.class,
          s.sesionPublicaId(),s.usuarioId(),u,q.problemaId(),q.tratamientoId());
    }
    public Long crearVariedad(SessionIdentity s,long u,GpWebTypes.CatalogoVariedad q){
        return db.queryForObject("EXEC prod.PA_GP_Variedad_Ins_Catalogo ?,?,?,?,?,?,?",Long.class,
            s.sesionPublicaId(),s.usuarioId(),u,q.cultivoId(),q.codigo(),q.nombre(),q.descripcion());
    }
    public Long actualizarCatalogo(SessionIdentity s,long u,String tipo,long id,GpWebTypes.CatalogoActualizar q){
        return db.queryForObject("EXEC prod.PA_GP_Catalogo_Upd_Registro ?,?,?,?,?,?,?,?,?,?",Long.class,
            s.sesionPublicaId(),s.usuarioId(),u,tipo,id,q.padreId(),q.codigo(),q.nombre(),q.descripcion(),q.estado());
    }

}
