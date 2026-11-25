package com.franco.desco.application.caja;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/** Horarios semanales por UOT; no altera perfiles, permisos ni vínculos de empleados. */
@Service
public class HorarioComercialService {
    private final JdbcTemplate jdbc;
    public HorarioComercialService(JdbcTemplate jdbc) { this.jdbc=jdbc; }

    public record Empleado(Long empleadoId,Long usuarioId,String nombre,String codigo,
                           String area,String cargo,boolean habilitadoPos) {}
    public record Bloque(Integer diaSemana,String horaInicio,String horaFin) {}
    private record Segmento(long empleado,int dia,int inicio,int fin) {}
    public record Turno(Long horarioId,Long empleadoId,Integer diaSemana,String horaInicio,String horaFin) {}
    public record Atencion(Long uotId,String horaInicio,String horaFin) {}
    public record AtencionDia(int diaSemana,String horaInicio,String horaFin,boolean personalizado) {}
    public record Planilla(Atencion atencion,List<AtencionDia> diasAtencion,List<Empleado> empleados,List<Turno> turnos) {}
    private List<AtencionDia> diasAtencion(long uot, Atencion general) {
        var excepciones = jdbc.query("""
            SELECT dia_semana,CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
            FROM comercial.HorarioAtencionDiaPOS WHERE uot_id=?
            """,(rs,n)->new AtencionDia(rs.getInt(1),rs.getString(2),rs.getString(3),true),uot);
        List<AtencionDia> dias = new ArrayList<>();
        for (int dia=1; dia<=7; dia++) {
            final int actual=dia;
            dias.add(excepciones.stream().filter(d->d.diaSemana()==actual).findFirst()
                .orElse(new AtencionDia(dia,general.horaInicio(),general.horaFin(),false)));
        }
        return List.copyOf(dias);
    }
    public record Resultado(Long id,String mensaje) {}
    public record AccesoResultado(Long empleadoId,boolean habilitado,String mensaje) {}

    private void require(boolean condition,String message) {
        if(!condition) throw new CajaPosService.Regla(message);
    }
    private void authorize(long usuario,long uot,String permiso) {
        Integer value=jdbc.queryForObject("SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                Integer.class,usuario,uot,permiso);
        require(value!=null && value==1,"No tienes permisos para esta acción.");
    }
    public record MiHorario(Long empleadoId,String nombre,List<Turno> turnos,Atencion atencion,List<AtencionDia> diasAtencion) {}
    @Transactional(readOnly=true)
    public MiHorario mio(long usuario,long uot) {
        authorize(usuario,uot,"PERSONAL_COMERCIAL_PROPIO");
        var empleados=jdbc.query("""
          SELECT E.empleado_id,CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))
          FROM seg.Usuario U JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
          JOIN org.Persona P ON P.persona_id=E.empleado_id
          JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=? AND EU.estado=1
          WHERE U.usuario_id=? AND U.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
            AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
          """,(rs,n)->new Object[]{rs.getLong(1),rs.getString(2)},uot,usuario);
        // Una cuenta administradora puede consultar esta vista sin ser empleado de la UOT.
        // No se consultan horarios de terceros ni se considera un error funcional.
        if (empleados.isEmpty()) {
            var configuracion=jdbc.query("""
              SELECT uot_id,CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
              FROM comercial.HorarioAtencionUOT WHERE uot_id=?
              """,(rs,n)->new Atencion(rs.getLong(1),rs.getString(2),rs.getString(3)),uot);
            Atencion general=configuracion.isEmpty()?new Atencion(uot,"07:00","20:00"):configuracion.getFirst();
            return new MiHorario(null,"",List.of(),general,diasAtencion(uot,general));
        }
        var actual=empleados.getFirst();long empleado=(Long)actual[0];
        var turnos=jdbc.query("""
          SELECT horario_id,empleado_id,dia_semana,CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
          FROM comercial.HorarioEmpleadoPOS WHERE uot_id=? AND empleado_id=? ORDER BY dia_semana,hora_inicio
          """,(rs,n)->new Turno(rs.getLong(1),rs.getLong(2),rs.getInt(3),rs.getString(4),rs.getString(5)),uot,empleado);
        var configuracion=jdbc.query("""
          SELECT uot_id,CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
          FROM comercial.HorarioAtencionUOT WHERE uot_id=?
          """,(rs,n)->new Atencion(rs.getLong(1),rs.getString(2),rs.getString(3)),uot);
        Atencion general=configuracion.isEmpty()?new Atencion(uot,"07:00","20:00"):configuracion.getFirst();
        return new MiHorario(empleado,(String)actual[1],turnos,general,diasAtencion(uot,general));
    }

    @Transactional(readOnly=true)
    public Planilla planilla(long usuario,long uot) {
        authorize(usuario,uot,"PERSONAL_COMERCIAL_LISTAR");
        var empleados=jdbc.query("""
            SELECT E.empleado_id,U.usuario_id,
              LTRIM(RTRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N'')))),
              COALESCE(EU.codigo_empleado,E.codigo_empleado,N''),COALESCE(EA.area,N''),COALESCE(EA.cargo,N''),
              CASE WHEN AX.habilitado=0 THEN 0 ELSE 1 END
            FROM org.Empleado E JOIN org.Persona P ON P.persona_id=E.empleado_id
            JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=?
                AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
                AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
            OUTER APPLY(
              SELECT TOP(1) A.nombre area,EA0.cargo
              FROM org.EmpleadoArea EA0 JOIN org.Area A ON A.area_id=EA0.area_id AND A.uot_id=EU.uot_id
              WHERE EA0.empleado_id=E.empleado_id AND EA0.estado=1 AND EA0.fecha_hasta IS NULL
              ORDER BY EA0.fecha_desde DESC,EA0.empleado_area_id DESC
            ) EA
            JOIN seg.Usuario U ON U.persona_id=E.empleado_id AND U.estado=1
            LEFT JOIN comercial.AccesoEmpleadoPOS AX ON AX.uot_id=EU.uot_id AND AX.empleado_id=E.empleado_id
            WHERE E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
              AND U.usuario_id IS NOT NULL
              AND (AX.habilitado=0 OR (
                  seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'POS_OPERAR')=1
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_ABRIR')=1
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_CERRAR')=1))
            ORDER BY P.apellido_paterno,P.nombres,E.empleado_id
            """,(rs,n)->new Empleado(rs.getLong(1),(Long)rs.getObject(2),rs.getString(3),
                 rs.getString(4),rs.getString(5),rs.getString(6),rs.getInt(7)==1),uot,uot,uot,uot);
        var turnos=jdbc.query("""
            SELECT H.horario_id,H.empleado_id,H.dia_semana,CONVERT(VARCHAR(5),H.hora_inicio,108),
                   CONVERT(VARCHAR(5),H.hora_fin,108)
            FROM comercial.HorarioEmpleadoPOS H WHERE H.uot_id=?
            ORDER BY H.dia_semana,H.hora_inicio,H.empleado_id,H.horario_id
            """,(rs,n)->new Turno(rs.getLong(1),rs.getLong(2),rs.getInt(3),rs.getString(4),rs.getString(5)),uot);
        var configs=jdbc.query("""
            SELECT uot_id,CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
            FROM comercial.HorarioAtencionUOT WHERE uot_id=?
            """,(rs,n)->new Atencion(rs.getLong(1),rs.getString(2),rs.getString(3)),uot);
        Atencion general=configs.isEmpty()?new Atencion(uot,"07:00","20:00"):configs.getFirst();
        return new Planilla(general,diasAtencion(uot,general),empleados,turnos);
    }
    private LocalTime time(String s) {
        require(s!=null && s.matches("([01][0-9]|2[0-3]):[0-5][0-9]"),"Hora inválida. Use HH:mm.");
        return LocalTime.parse(s);
    }
    @Transactional
    public Resultado atencion(long usuario,long uot,String inicio,String fin) {
        authorize(usuario,uot,"HORARIO_COMERCIAL_CONFIGURAR");
        LocalTime a=time(inicio),b=time(fin);
        require(a.isBefore(b),"La hora de apertura debe ser menor que la de cierre.");
        // No recortar silenciosamente turnos ya programados.
        Long incompatible=jdbc.queryForObject("""
            SELECT COUNT_BIG(*) FROM comercial.HorarioEmpleadoPOS WITH(UPDLOCK,HOLDLOCK)
            WHERE uot_id=? AND (hora_inicio<? OR hora_fin>?)
            """,Long.class,uot,java.sql.Time.valueOf(a),java.sql.Time.valueOf(b));
        require(incompatible!=null && incompatible==0,"Hay turnos fuera del nuevo horario. Ajústelos antes.");
        int updated=jdbc.update("""
            UPDATE comercial.HorarioAtencionUOT SET hora_inicio=?,hora_fin=?,usuario_actualizacion_id=?,
              fecha_actualizacion=SYSUTCDATETIME() WHERE uot_id=?
            """,java.sql.Time.valueOf(a),java.sql.Time.valueOf(b),usuario,uot);
        if(updated==0) jdbc.update("""
            INSERT comercial.HorarioAtencionUOT(uot_id,hora_inicio,hora_fin,usuario_actualizacion_id)
            VALUES(?,?,?,?)
            """,uot,java.sql.Time.valueOf(a),java.sql.Time.valueOf(b),usuario);
        return new Resultado(uot,"Horario de atención actualizado.");
    }
    @Transactional
    public Resultado guardar(long usuario,long uot,long empleado,List<Bloque> bloques,boolean autorizarCoincidencia,String motivoCoincidencia) {
        authorize(usuario,uot,"PERSONAL_COMERCIAL_EDITAR");
        require(bloques!=null && bloques.size()<=28,"Máximo 28 bloques por empleado.");
        Long habilitado=jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM org.Empleado E
          JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=? AND EU.estado=1
            AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
            AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
          JOIN seg.Usuario U ON U.persona_id=E.empleado_id AND U.estado=1
          WHERE E.empleado_id=? AND E.estado=1
            AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'POS_OPERAR')=1
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_ABRIR')=1
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_CERRAR')=1
          """,Long.class,uot,empleado,uot,uot,uot);
        require(habilitado!=null && habilitado>0,"El empleado no está habilitado para turnos de venta.");
        Long suspendido=jdbc.queryForObject("SELECT COUNT_BIG(*) FROM comercial.AccesoEmpleadoPOS WHERE uot_id=? AND empleado_id=? AND habilitado=0",Long.class,uot,empleado);
        require(suspendido!=null && suspendido==0,"El empleado tiene el acceso comercial suspendido.");
        // Serializar antes de consultar atención para evitar carreras con cambios de jornada.
        var locked=jdbc.query("""
          SELECT U.uot_id FROM org.UOT U WITH(UPDLOCK,HOLDLOCK) WHERE U.uot_id=? AND U.estado=1
          """,(rs,n)->rs.getLong(1),uot);
        require(!locked.isEmpty(),"UOT no disponible.");
        var cfg=jdbc.query("""
          SELECT CONVERT(VARCHAR(5),hora_inicio,108),CONVERT(VARCHAR(5),hora_fin,108)
          FROM comercial.HorarioAtencionUOT WHERE uot_id=?
          """,(rs,n)->List.of(rs.getString(1),rs.getString(2)),uot);
        Atencion general=new Atencion(uot,cfg.isEmpty()?"07:00":cfg.getFirst().get(0),
            cfg.isEmpty()?"20:00":cfg.getFirst().get(1));
        var dias=diasAtencion(uot,general);
        var validated=new ArrayList<Bloque>();
        for(Bloque b:bloques) {
            require(b!=null && b.diaSemana()!=null && b.diaSemana()>=1 && b.diaSemana()<=7,
                    "Día de semana no válido.");
            LocalTime a=time(b.horaInicio()),end=time(b.horaFin());
            AtencionDia dia=dias.get(b.diaSemana()-1);
            require(!a.isBefore(time(dia.horaInicio())) && !end.isAfter(time(dia.horaFin())) && a.isBefore(end),
                    "Los turnos deben estar dentro del horario de atención.");
            validated.add(new Bloque(b.diaSemana(),a.toString(),end.toString()));
        }
        validated.sort(Comparator.comparing(Bloque::diaSemana).thenComparing(Bloque::horaInicio));
        for(int i=1;i<validated.size();i++) {
            Bloque previous=validated.get(i-1),current=validated.get(i);
            require(!previous.diaSemana().equals(current.diaSemana()) ||
                    !time(previous.horaFin()).isAfter(time(current.horaInicio())),
                    "El empleado tiene bloques horarios superpuestos.");
        }
        List<Segmento> segmentos=jdbc.query("""
          SELECT H.empleado_id,H.dia_semana,DATEPART(HOUR,H.hora_inicio)*60+DATEPART(MINUTE,H.hora_inicio),
            DATEPART(HOUR,H.hora_fin)*60+DATEPART(MINUTE,H.hora_fin)
          FROM comercial.HorarioEmpleadoPOS H WITH(UPDLOCK,HOLDLOCK)
          LEFT JOIN comercial.AccesoEmpleadoPOS AX ON AX.uot_id=H.uot_id AND AX.empleado_id=H.empleado_id
          WHERE H.uot_id=? AND H.empleado_id<>? AND ISNULL(AX.habilitado,1)=1
          """,(rs,n)->new Segmento(rs.getLong(1),rs.getInt(2),rs.getInt(3),rs.getInt(4)),uot,empleado);
        for(Bloque b:validated) segmentos.add(new Segmento(empleado,b.diaSemana(),
              time(b.horaInicio()).toSecondOfDay()/60,time(b.horaFin()).toSecondOfDay()/60));
        boolean tieneCoincidencia=false;
        for(Segmento a:segmentos) if(a.empleado()==empleado)
            for(Segmento b:segmentos) if(b.dia()==a.dia() && b.empleado()!=empleado &&
                 a.inicio()<b.fin() && b.inicio()<a.fin()) tieneCoincidencia=true;
        // Se registran coincidencias para consulta, sin impedir la cobertura flexible.
        jdbc.update("DELETE FROM comercial.HorarioEmpleadoPOS WHERE uot_id=? AND empleado_id=?",uot,empleado);
        for(Bloque b:validated) jdbc.update("""
          INSERT comercial.HorarioEmpleadoPOS(uot_id,empleado_id,dia_semana,hora_inicio,hora_fin,usuario_registro_id,
              coincidencia_autorizada,motivo_coincidencia)
          VALUES(?,?,?,?,?,?,?,?)
          """,uot,empleado,b.diaSemana(),java.sql.Time.valueOf(time(b.horaInicio())),
                  java.sql.Time.valueOf(time(b.horaFin())),usuario,
                  tieneCoincidencia,motivoCoincidencia==null || motivoCoincidencia.isBlank()?null:motivoCoincidencia.trim());
        return new Resultado(empleado,"Turnos semanales actualizados.");
    }

    /** Suspende solo permisos del módulo comercial en esta UOT; nunca bloquea la cuenta completa. */
    @Transactional
    public AccesoResultado cambiarAcceso(long responsable,long uot,long empleado,boolean habilitar,String motivo) {
        authorize(responsable,uot,"PERSONAL_COMERCIAL_HABILITAR");
        require(motivo!=null && motivo.trim().length()>=5 && motivo.trim().length()<=270,
                "Indique un motivo de 5 a 270 caracteres.");
        // Bloqueo de serialización por UOT para evitar carrera con la planificación de turnos.
        require(!jdbc.query("SELECT uot_id FROM org.UOT WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=? AND estado=1",
                (rs,n)->rs.getLong(1),uot).isEmpty(),"UOT no disponible.");
        var usuarios=jdbc.query("""
            SELECT U.usuario_id,UU.usuario_uot_id
            FROM org.Empleado E
            JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=? AND EU.estado=1
              AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
              AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
            JOIN seg.Usuario U ON U.persona_id=E.empleado_id AND U.estado=1
            JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id AND UU.uot_id=EU.uot_id AND UU.estado=1
              AND UU.fecha_desde<=SYSUTCDATETIME() AND (UU.fecha_hasta IS NULL OR UU.fecha_hasta>SYSUTCDATETIME())
            WHERE E.empleado_id=? AND E.estado=1
            """,(rs,n)->new long[]{rs.getLong(1),rs.getLong(2)},uot,empleado);
        require(usuarios.size()==1,"Empleado sin cuenta vigente o con asignaciones ambiguas en esta UOT.");
        long usuario=usuarios.getFirst()[0],usuarioUot=usuarios.getFirst()[1];
        require(usuario!=responsable,"No puedes suspender tu propio acceso comercial.");
        require(jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM seg.UsuarioUOTRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id
          WHERE UR.usuario_uot_id=? AND UR.estado=1 AND UR.fecha_hasta IS NULL
            AND R.codigo='ADMINISTRADOR' AND R.estado=1
          """,Long.class,usuarioUot)==0,"No se suspende a un administrador desde gestión comercial.");
        require(jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM seg.UsuarioRol UR JOIN seg.Rol R ON R.rol_id=UR.rol_id
          WHERE UR.usuario_id=? AND UR.estado=1 AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
            AND R.codigo='ADMINISTRADOR' AND R.estado=1
          """,Long.class,usuario)==0,"No se suspende a un administrador desde gestión comercial.");
        var flag=jdbc.query("SELECT habilitado FROM comercial.AccesoEmpleadoPOS WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=? AND empleado_id=?",
                (rs,n)->rs.getBoolean(1),uot,empleado);
        boolean actual=flag.isEmpty()||flag.getFirst();
        if(actual==habilitar) return new AccesoResultado(empleado,habilitar,"El estado ya estaba actualizado.");
        if(!habilitar) {
            // Comprueba acceso real antes de suspender. Si fue suspendido antes se conserva el registro.
            require(jdbc.queryForObject("""
               SELECT COUNT_BIG(*) FROM seg.UsuarioUOT UU WHERE UU.usuario_uot_id=? AND UU.estado=1
                 AND seg.FN_Usuario_TienePermisoUOT(?,?, 'POS_OPERAR')=1
                 AND seg.FN_Usuario_TienePermisoUOT(?,?, 'CAJAS_ABRIR')=1
                 AND seg.FN_Usuario_TienePermisoUOT(?,?, 'CAJAS_CERRAR')=1
               """,Long.class,usuarioUot,usuario,uot,usuario,uot,usuario,uot)>0,
               "El empleado no cumple los permisos mínimos para ventas y caja.");
            jdbc.update("""
                INSERT seg.UsuarioUOTPermiso(usuario_uot_id,permiso_id,permitido,motivo,fecha_desde,estado,asignado_por_usuario_id)
                SELECT ?,P.permiso_id,0,?,SYSUTCDATETIME(),1,?
                FROM seg.Permiso P JOIN seg.Modulo M ON M.modulo_id=P.modulo_id
                JOIN seg.Modulo ROOT ON ROOT.codigo='GRP_COMERCIAL' AND ROOT.estado=1
                WHERE P.estado=1 AND (M.modulo_id=ROOT.modulo_id OR M.modulo_padre_id=ROOT.modulo_id
                  OR EXISTS(SELECT 1 FROM seg.Modulo MID WHERE MID.modulo_id=M.modulo_padre_id
                    AND MID.modulo_padre_id=ROOT.modulo_id))
                  AND NOT EXISTS(SELECT 1 FROM seg.UsuarioUOTPermiso X WITH(UPDLOCK,HOLDLOCK)
                    WHERE X.usuario_uot_id=? AND X.permiso_id=P.permiso_id AND X.estado=1
                      AND LEFT(X.motivo,24)=N'[HORARIO_POS_SUSPENSION]')
                """.toString(),usuarioUot,"[HORARIO_POS_SUSPENSION] "+motivo.trim(),responsable,usuarioUot);
        } else {
            // Solo revierte las denegaciones creadas por este flujo, no las previas de otro administrador.
            jdbc.update("""
                UPDATE X SET estado=0,fecha_hasta=SYSUTCDATETIME()
                FROM seg.UsuarioUOTPermiso X WHERE X.usuario_uot_id=? AND X.estado=1
                   AND X.permitido=0 AND LEFT(X.motivo,24)=N'[HORARIO_POS_SUSPENSION]'
                """,usuarioUot);
            for(String permiso:List.of("POS_OPERAR","CAJAS_ABRIR","CAJAS_CERRAR"))
                authorize(usuario,uot,permiso);
        }
        int n=jdbc.update("""
           UPDATE comercial.AccesoEmpleadoPOS
           SET habilitado=?,motivo=?,usuario_actualizacion_id=?,fecha_actualizacion=SYSUTCDATETIME()
           WHERE uot_id=? AND empleado_id=?
           """,habilitar,motivo.trim(),responsable,uot,empleado);
        if(n==0) jdbc.update("""
           INSERT comercial.AccesoEmpleadoPOS(uot_id,empleado_id,habilitado,motivo,usuario_actualizacion_id)
           VALUES(?,?,?,?,?)
           """,uot,empleado,habilitar,motivo.trim(),responsable);
        return new AccesoResultado(empleado,habilitar,habilitar?"Acceso comercial habilitado.":"Acceso comercial suspendido.");
    }
}
