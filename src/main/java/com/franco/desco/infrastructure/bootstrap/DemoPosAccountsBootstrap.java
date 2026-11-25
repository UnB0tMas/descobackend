package com.franco.desco.infrastructure.bootstrap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/** Datos de prueba locales: solo en las dos bases DEV permitidas. */
@Component
@ConditionalOnProperty(prefix="desco.demo.pos", name="enabled", havingValue="true", matchIfMissing=false)
@Order(30)
public class DemoPosAccountsBootstrap implements ApplicationRunner {
    private static final Logger log=LoggerFactory.getLogger(DemoPosAccountsBootstrap.class);
    private static final String SARA="UOT_LEGACY_4";
    // Clave fija exclusivamente para Valeria en la base de desarrollo.
    private static final String VALERIA_LOGIN="pos_sarasara_01";
    private static final String VALERIA_DEV_PASSWORD="ValeriaDemo#2026!";
    private static final String[] BASE={
        "POS_OPERAR","CAJAS_LISTAR","CAJAS_ABRIR","CAJAS_CERRAR",
        "VENTAS_HISTORIAL","VENTAS_REPORTES","COMPROBANTES_VER","PERSONAL_COMERCIAL_PROPIO"
    };
    private static final String[] MANAGER={
        "PERSONAL_COMERCIAL_LISTAR","PERSONAL_COMERCIAL_EDITAR",
        "PERSONAL_COMERCIAL_HABILITAR","HORARIO_COMERCIAL_CONFIGURAR"
    };
    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;
    private final String configuredPassword;

    private record Demo(String login,String documento,String nombres,String paterno,String materno,String rol) {}
    private static final List<Demo> DEMOS=List.of(
        new Demo("pos_sarasara_01","DESCO-POS-DEMO-01","Valeria","Flores","Rojas","POS_DEMO_BASE"),
        new Demo("pos_sarasara_02","DESCO-POS-DEMO-02","Diego","Quispe","Cárdenas","POS_DEMO_FLEX"),
        new Demo("pos_sarasara_03","DESCO-POS-DEMO-03","Mariana","Torres","Medina","POS_DEMO_LIBRE")
    );

    public DemoPosAccountsBootstrap(JdbcTemplate jdbc,PasswordEncoder encoder,
                                    @Value("${desco.demo.pos.password:}") String configuredPassword) {
        this.jdbc=jdbc;
        this.encoder=encoder;
        this.configuredPassword=configuredPassword;
    }

    private long one(String sql,Object... args) {
        List<Long> values=jdbc.query(sql,(rs,i)->rs.getLong(1),args);
        if(values.size()!=1) throw new IllegalStateException("Referencia comercial inexistente o ambigua.");
        return values.getFirst();
    }

    private long activeRole(String code,String name) {
        var rows=jdbc.query("SELECT rol_id,estado FROM seg.Rol WHERE codigo=?",
                (rs,i)->new long[]{rs.getLong(1),rs.getBoolean(2)?1:0},code);
        if(rows.isEmpty()) {
            jdbc.update("""
                INSERT seg.Rol(codigo,nombre,descripcion,estado,requiere_segundo_factor,es_sistema)
                VALUES(?,?,N'Perfil exclusivo de pruebas de caja en Sara Sara.',1,0,0)
                """,code,name);
            return one("SELECT rol_id FROM seg.Rol WHERE codigo=? AND estado=1",code);
        }
        if(rows.size()!=1) throw new IllegalStateException("Perfil demo duplicado: "+code);
        if(rows.getFirst()[1]!=1)
            jdbc.update("UPDATE seg.Rol SET estado=1 WHERE rol_id=?",rows.getFirst()[0]);
        return rows.getFirst()[0];
    }

    private long permission(String code) {
        var rows=jdbc.query("SELECT permiso_id,estado FROM seg.Permiso WHERE codigo=?",
                (rs,i)->new long[]{rs.getLong(1),rs.getBoolean(2)?1:0},code);
        if(rows.size()!=1 || rows.getFirst()[1]!=1)
            throw new IllegalStateException("Falta el permiso comercial activo: "+code);
        return rows.getFirst()[0];
    }

    private void exceptionPermission(String code,String name,long module) {
        var rows=jdbc.query("SELECT permiso_id,modulo_id,estado FROM seg.Permiso WHERE codigo=?",
                (rs,i)->new long[]{rs.getLong(1),rs.getLong(2),rs.getBoolean(3)?1:0},code);
        if(rows.isEmpty()) {
            jdbc.update("""
                INSERT seg.Permiso(modulo_id,codigo,nombre,descripcion,estado,accion,es_sensible,requiere_motivo)
                VALUES(?,?,?,N'Acceso excepcional a operaciones comerciales.',1,'CONFIRMAR',1,1)
                """,module,code,name);
        } else if(rows.size()!=1 || rows.getFirst()[1]!=module || rows.getFirst()[2]!=1) {
            throw new IllegalStateException("Permiso excepcional incompatible: "+code);
        }
    }

    private void grant(long role,String code) {
        long perm=permission(code);
        var rows=jdbc.query("SELECT estado FROM seg.RolPermiso WHERE rol_id=? AND permiso_id=?",
                (rs,i)->rs.getBoolean(1),role,perm);
        if(rows.isEmpty()) {
            jdbc.update("INSERT seg.RolPermiso(rol_id,permiso_id,estado,fecha_asignacion) VALUES(?,?,1,SYSUTCDATETIME())",role,perm);
        } else if(rows.size()!=1) {
            throw new IllegalStateException("Concesión demo duplicada: "+code);
        } else if(!rows.getFirst()) {
            jdbc.update("""
                UPDATE seg.RolPermiso SET estado=1,fecha_retiro=NULL,
                  retirado_por_usuario_id=NULL,motivo_retiro=NULL
                WHERE rol_id=? AND permiso_id=?
                """,role,perm);
        }
    }

    /** El perfil operativo no administra empleados ni horarios ajenos. Solo en DEV. */
    private void revokeManagerGrants(long role) {
        jdbc.update("""
            UPDATE RP
               SET estado=0,fecha_retiro=SYSUTCDATETIME(),
                   motivo_retiro=N'Perfil de operador de prueba sin funciones de administración'
              FROM seg.RolPermiso RP
              JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id
             WHERE RP.rol_id=? AND RP.estado=1
               AND P.codigo IN ('PERSONAL_COMERCIAL_LISTAR', 'PERSONAL_COMERCIAL_EDITAR',
                                'PERSONAL_COMERCIAL_HABILITAR', 'HORARIO_COMERCIAL_CONFIGURAR')
            """,role);
    }

    private void assertPassword(String pass) {
        if(pass.length()<12 || !pass.matches(".*[A-Z].*") || !pass.matches(".*[a-z].*")
             || !pass.matches(".*[0-9].*") || !pass.matches(".*[^A-Za-z0-9].*")) {
            throw new IllegalStateException("DESCO_DEMO_POS_PASSWORD requiere 12 caracteres, mayúscula, minúscula, número y símbolo.");
        }
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        String database=jdbc.queryForObject("SELECT DB_NAME()",String.class);
        if(database==null || !(database.equalsIgnoreCase("DESCO_DB_dev")
                || database.equalsIgnoreCase("DESCO_DB_dev2"))) {
            log.info("[POS DEMO] Se omiten las cuentas de prueba: base no DEV.");
            return;
        }
        long sara=one("SELECT uot_id FROM org.UOT WHERE codigo=? AND estado=1 AND es_raiz=0",SARA);
        long posModule=one("SELECT modulo_id FROM seg.Modulo WHERE codigo='POS' AND estado=1");
        // La clave de prueba solo cambia cuando el administrador la configura expresamente.
        // No generar ni publicar contraseñas distintas en cada reinicio.
        String pwd=(configuredPassword==null || configuredPassword.isBlank())?null:configuredPassword;
        if(pwd!=null) assertPassword(pwd);
        assertPassword(VALERIA_DEV_PASSWORD);

        exceptionPermission("POS_SIN_HORARIO","Operar sin horario",posModule);
        exceptionPermission("POS_SIN_CAJA","Operar sin caja asignada",posModule);
        long base=activeRole("POS_DEMO_BASE","Cajero de prueba con horario");
        long flex=activeRole("POS_DEMO_FLEX","Cajero de prueba sin horario");
        long libre=activeRole("POS_DEMO_LIBRE","Cajero de prueba sin horario ni caja");
        for(long rol:new long[]{base,flex,libre}) for(String code:BASE) grant(rol,code);
        // El perfil base es operativo: no recibe permisos de administración.
        revokeManagerGrants(base);
        grant(flex,"POS_SIN_HORARIO");
        grant(libre,"POS_SIN_HORARIO");
        grant(libre,"POS_SIN_CAJA");

        long area;
        var areas=jdbc.query("SELECT area_id,estado FROM org.Area WHERE uot_id=? AND codigo='POS_DEMO'",
                (rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2)},sara);
        if(areas.size()>1) throw new IllegalStateException("Área POS de prueba duplicada en Sara Sara.");
        if(areas.isEmpty()) {
            jdbc.update("""
                INSERT org.Area(uot_id,empresa_id,codigo,nombre,estado)
                VALUES(?,(SELECT empresa_legacy_id FROM org.UOT WHERE uot_id=?),'POS_DEMO',N'Punto de venta',1)
                """,sara,sara);
        } else if(!(Boolean)areas.getFirst()[1]) {
            jdbc.update("UPDATE org.Area SET estado=1 WHERE area_id=?",areas.getFirst()[0]);
        }
        area=one("SELECT area_id FROM org.Area WHERE uot_id=? AND codigo='POS_DEMO' AND estado=1",sara);
        for(Demo d:DEMOS) {
            long persona=ensurePerson(d);
            ensureEmployee(persona,d,sara,area);
            // No cambia las contraseñas de las otras cuentas de prueba.
            String demoPassword=VALERIA_LOGIN.equals(d.login())?VALERIA_DEV_PASSWORD:pwd;
            long user=ensureUser(persona,d,demoPassword);
            ensureSecurityMail(user,d.login());
            ensureEmployeeUot(persona,sara,d.documento());
            long usuarioUot=ensureUserUot(user,sara);
            long role=switch(d.rol()) {
                case "POS_DEMO_BASE" -> base;
                case "POS_DEMO_FLEX" -> flex;
                case "POS_DEMO_LIBRE" -> libre;
                default -> throw new IllegalStateException("Perfil de prueba no reconocido.");
            };
            ensureUserUotRole(usuarioUot,role);
            ensurePosAccess(persona,sara,user);
            clearDemoDenials(usuarioUot,d);
            for(String p:BASE) requireEffective(user,sara,p);
            if(d.rol().equals("POS_DEMO_FLEX") || d.rol().equals("POS_DEMO_LIBRE"))
                requireEffective(user,sara,"POS_SIN_HORARIO");
            if(d.rol().equals("POS_DEMO_LIBRE")) requireEffective(user,sara,"POS_SIN_CAJA");
            if(d.rol().equals("POS_DEMO_BASE"))
                for(String p:MANAGER) {
                    Integer allowed=jdbc.queryForObject(
                        "SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                        Integer.class,user,sara,p);
                    if(allowed!=null && allowed==1)
                        throw new IllegalStateException("El operador demo conserva permisos administrativos: "+p);
                }
        }
        Long disponibles=jdbc.queryForObject("""
            SELECT COUNT(DISTINCT U.usuario_id) FROM seg.Usuario U
            JOIN org.Empleado E ON E.empleado_id=U.persona_id AND E.estado=1
            JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=?
               AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
               AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
            WHERE U.nombre_usuario IN ('pos_sarasara_01','pos_sarasara_02','pos_sarasara_03')
              AND U.estado=1 AND U.estado_cuenta='ACTIVA'
              AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME()))
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'POS_OPERAR')=1
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_ABRIR')=1
              AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_CERRAR')=1
            """,Long.class,sara,sara,sara,sara);
        if(disponibles==null || disponibles!=3)
            throw new IllegalStateException("No se habilitaron exactamente tres empleados comerciales en Sara Sara.");
        log.info("[POS DEMO] Tres empleados comerciales verificados en UOT Sara Sara (id={}).",sara);

    }

    private long ensurePerson(Demo d) {
        var rows=jdbc.query("""
            SELECT persona_id,nombres,apellido_paterno,apellido_materno,estado
            FROM org.Persona WHERE tipo_documento='OTRO' AND numero_documento=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getString(2),rs.getString(3),rs.getString(4),rs.getBoolean(5)},d.documento());
        if(rows.size()>1) throw new IllegalStateException("Documento demo duplicado: "+d.documento());
        if(rows.isEmpty()) {
            jdbc.update("""
                INSERT org.Persona(tipo_documento,numero_documento,nombres,apellido_paterno,apellido_materno,estado,tipo_persona)
                VALUES('OTRO',?,?,?,?,1,'NATURAL')
                """,d.documento(),d.nombres(),d.paterno(),d.materno());
        } else {
            Object[] p=rows.getFirst();
            if(!d.nombres().equals(p[1]) || !d.paterno().equals(p[2]) || !d.materno().equals(p[3]))
                throw new IllegalStateException("Documento demo utilizado por otra persona: "+d.documento());
            if(!(Boolean)p[4])
                jdbc.update("UPDATE org.Persona SET estado=1 WHERE persona_id=?",p[0]);
        }
        return one("SELECT persona_id FROM org.Persona WHERE tipo_documento='OTRO' AND numero_documento=?",d.documento());
    }

    private void ensureEmployee(long persona,Demo d,long sara,long area) {
        var empleados=jdbc.query("SELECT estado,codigo_empleado,fecha_cese FROM org.Empleado WHERE empleado_id=?",
                (rs,i)->new Object[]{rs.getBoolean(1),rs.getString(2),rs.getDate(3)},persona);
        if(empleados.isEmpty()) {
            jdbc.update("""
                INSERT org.Empleado(empleado_id,empresa_id,codigo_empleado,fecha_ingreso,estado)
                VALUES(?,(SELECT empresa_legacy_id FROM org.UOT WHERE uot_id=?),?,CONVERT(DATE,SYSUTCDATETIME()),1)
                """,persona,sara,d.documento());
        } else {
            if(empleados.size()!=1 || !d.documento().equals(empleados.getFirst()[1]))
                throw new IllegalStateException("Empleado demo incompatible: "+d.login());
            jdbc.update("""
                UPDATE org.Empleado SET estado=1,fecha_cese=NULL
                WHERE empleado_id=? AND (estado=0 OR fecha_cese IS NOT NULL)
                """,persona);
        }
        var areas=jdbc.query("""
            SELECT empleado_area_id,estado,fecha_hasta FROM org.EmpleadoArea
            WHERE empleado_id=? AND area_id=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2),rs.getDate(3)},persona,area);
        if(areas.size()>1) throw new IllegalStateException("Área demo duplicada: "+d.login());
        if(areas.isEmpty()) {
            jdbc.update("""
                INSERT org.EmpleadoArea(empleado_id,area_id,cargo,fecha_desde,estado)
                VALUES(?,?,N'Cajero de prueba',CONVERT(DATE,SYSUTCDATETIME()),1)
                """,persona,area);
        } else if(!(Boolean)areas.getFirst()[1] || areas.getFirst()[2]!=null) {
            jdbc.update("""
                UPDATE org.EmpleadoArea SET estado=1,fecha_desde=CONVERT(DATE,SYSUTCDATETIME()),fecha_hasta=NULL
                WHERE empleado_area_id=?
                """,areas.getFirst()[0]);
        }
    }

    private long ensureUser(long persona,Demo d,String pwd) {
        var users=jdbc.query("""
            SELECT usuario_id,persona_id,password_hash,estado,estado_cuenta,
                   requiere_cambio_password,segundo_factor_habilitado,omitir_segundo_factor_pruebas
            FROM seg.Usuario WHERE nombre_usuario=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getBoolean(4),
                    rs.getString(5),rs.getBoolean(6),rs.getBoolean(7),rs.getBoolean(8)},d.login());
        if(users.size()>1 || (!users.isEmpty() && !((Long)users.getFirst()[1]).equals(persona)))
            throw new IllegalStateException("El login demo pertenece a otra persona: "+d.login());
        if(users.isEmpty()) {
            if(pwd==null) throw new IllegalStateException(
                    "Configure DESCO_DEMO_POS_PASSWORD para crear las cuentas POS de prueba.");
            jdbc.update("""
                INSERT seg.Usuario(persona_id,nombre_usuario,password_hash,estado,estado_cuenta,
                       requiere_cambio_password,segundo_factor_habilitado,omitir_segundo_factor_pruebas,fecha_cambio_password)
                VALUES(?,?,?,1,'ACTIVA',0,0,1,SYSUTCDATETIME())
                """,persona,d.login(),encoder.encode(pwd));
        } else {
            Object[] u=users.getFirst();
            boolean requiereReparacion=!(Boolean)u[3] || !"ACTIVA".equals(u[4])
                    || (Boolean)u[5] || (Boolean)u[6] || !(Boolean)u[7];
            if(pwd==null && requiereReparacion) throw new IllegalStateException(
                    "Configure DESCO_DEMO_POS_PASSWORD para rehabilitar la cuenta de prueba.");
            if(pwd!=null && (!encoder.matches(pwd,(String)u[2]) || requiereReparacion)) {
                jdbc.update("""
                    UPDATE seg.Usuario SET password_hash=?,estado=1,estado_cuenta='ACTIVA',
                      fecha_cambio_password=SYSUTCDATETIME(),requiere_cambio_password=0,
                      segundo_factor_habilitado=0,omitir_segundo_factor_pruebas=1,
                      intentos_fallidos=0,fecha_ultimo_intento_fallido=NULL,bloqueado_hasta=NULL,
                      token_version=token_version+1
                    WHERE usuario_id=?
                    """,encoder.encode(pwd),u[0]);
            }
        }
        return one("SELECT usuario_id FROM seg.Usuario WHERE nombre_usuario=?",d.login());
    }

    private void ensureSecurityMail(long user,String login) {
        var active=jdbc.query("""
            SELECT usuario_correo_seguridad_id,es_verificado FROM seg.UsuarioCorreoSeguridad
            WHERE usuario_id=? AND estado=1 AND fecha_hasta IS NULL
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2)},user);
        if(active.size()>1) throw new IllegalStateException("Correo de seguridad demo ambiguo: "+login);
        if(!active.isEmpty()) {
            if(!(Boolean)active.getFirst()[1]) jdbc.update("""
                UPDATE seg.UsuarioCorreoSeguridad SET es_verificado=1,fecha_verificacion=SYSUTCDATETIME()
                WHERE usuario_correo_seguridad_id=?
                """,active.getFirst()[0]);
            return;
        }
        String mail=login+"@demo.invalid";
        jdbc.update("""
            INSERT seg.UsuarioCorreoSeguridad(usuario_id,correo,correo_normalizado,es_principal,es_verificado,
                 fecha_verificacion,fecha_desde,estado)
            VALUES(?,?,?,1,1,SYSUTCDATETIME(),SYSUTCDATETIME(),1)
            """,user,mail,mail);
    }

    private void ensureEmployeeUot(long persona,long uot,String code) {
        var rows=jdbc.query("""
            SELECT empleado_uot_id,estado,fecha_hasta FROM org.EmpleadoUOT
            WHERE empleado_id=? AND uot_id=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2),rs.getDate(3)},persona,uot);
        if(rows.size()>1) throw new IllegalStateException("Vínculo demo empleado/UOT ambiguo.");
        if(rows.isEmpty()) {
            Long principal=jdbc.queryForObject("""
                SELECT COUNT_BIG(*) FROM org.EmpleadoUOT WHERE empleado_id=? AND estado=1
                  AND fecha_hasta IS NULL AND es_principal=1
                """,Long.class,persona);
            jdbc.update("""
                INSERT org.EmpleadoUOT(empleado_id,uot_id,es_principal,fecha_desde,estado,codigo_empleado,fecha_ingreso)
                VALUES(?,?,?,CONVERT(DATE,SYSUTCDATETIME()),1,?,CONVERT(DATE,SYSUTCDATETIME()))
                """,persona,uot,principal==null||principal==0,code);
        } else if(!(Boolean)rows.getFirst()[1] || rows.getFirst()[2]!=null) {
            jdbc.update("""
                UPDATE org.EmpleadoUOT SET estado=1,fecha_desde=CONVERT(DATE,SYSUTCDATETIME()),
                    fecha_hasta=NULL,fecha_cese=NULL,codigo_empleado=?
                WHERE empleado_uot_id=?
                """,code,rows.getFirst()[0]);
        }
    }

    private long ensureUserUot(long user,long uot) {
        var rows=jdbc.query("""
            SELECT usuario_uot_id,estado,fecha_hasta FROM seg.UsuarioUOT
            WHERE usuario_id=? AND uot_id=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2),rs.getTimestamp(3)},user,uot);
        if(rows.size()>1) throw new IllegalStateException("Vínculo demo usuario/UOT ambiguo.");
        Long predet=jdbc.queryForObject("""
            SELECT COUNT_BIG(*) FROM seg.UsuarioUOT
            WHERE usuario_id=? AND estado=1 AND fecha_hasta IS NULL AND es_predeterminada=1
            """,Long.class,user);
        boolean predeterminada=predet==null||predet==0;
        if(rows.isEmpty()) {
            jdbc.update("""
                INSERT seg.UsuarioUOT(usuario_id,uot_id,es_predeterminada,fecha_desde,estado)
                VALUES(?,?,?,DATEADD(SECOND,-2,SYSUTCDATETIME()),1)
                """,user,uot,predeterminada);
        } else {
            // datetime2(0) redondea; una fecha del segundo siguiente aún no es vigente.
            // La reparación se limita al usuario DEMO actual y a su vínculo Sara Sara.
            jdbc.update("""
                UPDATE seg.UsuarioUOT SET estado=1,
                    fecha_desde=DATEADD(SECOND,-2,SYSUTCDATETIME()),fecha_hasta=NULL,
                    es_predeterminada=CASE WHEN estado=0 OR fecha_hasta IS NOT NULL
                        THEN ? ELSE es_predeterminada END
                WHERE usuario_uot_id=?
                  AND (estado=0 OR fecha_hasta IS NOT NULL OR fecha_desde>SYSUTCDATETIME())
                """,predeterminada,rows.getFirst()[0]);
        }
        return one("""
            SELECT usuario_uot_id FROM seg.UsuarioUOT
            WHERE usuario_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL
              AND fecha_desde<=SYSUTCDATETIME()
            """,user,uot);
    }

    private void ensureUserUotRole(long userUot,long role) {
        var rows=jdbc.query("""
            SELECT usuario_uot_rol_id,estado,fecha_hasta FROM seg.UsuarioUOTRol
            WHERE usuario_uot_id=? AND rol_id=?
            """,(rs,i)->new Object[]{rs.getLong(1),rs.getBoolean(2),rs.getTimestamp(3)},userUot,role);
        if(rows.size()>1) throw new IllegalStateException("Rol demo territorial ambiguo.");
        if(rows.isEmpty()) {
            jdbc.update("""
                INSERT seg.UsuarioUOTRol(usuario_uot_id,rol_id,fecha_desde,estado)
                VALUES(?,?,DATEADD(SECOND,-2,SYSUTCDATETIME()),1)
                """,userUot,role);
        } else {
            jdbc.update("""
                UPDATE seg.UsuarioUOTRol SET estado=1,
                    fecha_desde=DATEADD(SECOND,-2,SYSUTCDATETIME()),fecha_hasta=NULL
                WHERE usuario_uot_rol_id=?
                  AND (estado=0 OR fecha_hasta IS NOT NULL OR fecha_desde>SYSUTCDATETIME())
                """,rows.getFirst()[0]);
        }
    }

    private void ensurePosAccess(long person,long uot,long user) {
        var found=jdbc.query("SELECT habilitado FROM comercial.AccesoEmpleadoPOS WHERE empleado_id=? AND uot_id=?",
                (rs,i)->rs.getBoolean(1),person,uot);
        if(found.isEmpty()) {
            jdbc.update("""
                INSERT comercial.AccesoEmpleadoPOS(uot_id,empleado_id,habilitado,motivo,usuario_actualizacion_id)
                VALUES(?,?,1,N'Cuenta local de prueba',?)
                """,uot,person,user);
        } else if(found.size()!=1) {
            throw new IllegalStateException("Acceso POS demo duplicado.");
        } else if(!found.getFirst()) {
            jdbc.update("""
                UPDATE comercial.AccesoEmpleadoPOS SET habilitado=1,
                   motivo=N'Reactivación de cuenta local de prueba',usuario_actualizacion_id=?,
                   fecha_actualizacion=SYSUTCDATETIME() WHERE empleado_id=? AND uot_id=?
                """,user,person,uot);
        }
    }

    /** Solo en DEV: cierra denegaciones UOT de los tres logins demo, no de usuarios reales. */
    private void clearDemoDenials(long usuarioUot,Demo d) {
        List<String> permisos=new ArrayList<>(List.of(BASE));
        if(!d.rol().equals("POS_DEMO_BASE")) permisos.add("POS_SIN_HORARIO");
        if(d.rol().equals("POS_DEMO_LIBRE")) permisos.add("POS_SIN_CAJA");
        for(String code:permisos) {
            jdbc.update("""
                UPDATE UP SET estado=0,fecha_hasta=SYSUTCDATETIME()
                FROM seg.UsuarioUOTPermiso UP
                JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id
                WHERE UP.usuario_uot_id=? AND P.codigo=?
                  AND UP.estado=1 AND UP.permitido=0
                  AND UP.fecha_desde<=SYSUTCDATETIME()
                  AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta>SYSUTCDATETIME())
                """,usuarioUot,code);
        }
    }

    private void requireEffective(long user,long uot,String code) {
        Integer ok=jdbc.queryForObject("SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                Integer.class,user,uot,code);
        if(ok==null || ok!=1) {
            Long asignaciones=jdbc.queryForObject("""
                SELECT COUNT_BIG(*) FROM seg.UsuarioUOT
                WHERE usuario_id=? AND uot_id=? AND estado=1 AND fecha_hasta IS NULL
                  AND fecha_desde<=SYSUTCDATETIME()
                """,Long.class,user,uot);
            Long roles=jdbc.queryForObject("""
                SELECT COUNT_BIG(*) FROM seg.UsuarioUOT UU
                JOIN seg.UsuarioUOTRol UR ON UR.usuario_uot_id=UU.usuario_uot_id
                JOIN seg.Rol R ON R.rol_id=UR.rol_id AND R.estado=1
                JOIN seg.RolPermiso RP ON RP.rol_id=R.rol_id AND RP.estado=1
                JOIN seg.Permiso P ON P.permiso_id=RP.permiso_id AND P.codigo=? AND P.estado=1
                WHERE UU.usuario_id=? AND UU.uot_id=? AND UU.estado=1
                  AND UU.fecha_hasta IS NULL AND UU.fecha_desde<=SYSUTCDATETIME()
                  AND UR.estado=1 AND UR.fecha_desde<=SYSUTCDATETIME()
                  AND (UR.fecha_hasta IS NULL OR UR.fecha_hasta>SYSUTCDATETIME())
                """,Long.class,code,user,uot);
            Integer denegacion=jdbc.queryForObject("""
                SELECT COUNT(*) FROM seg.UsuarioUOT UU
                JOIN seg.UsuarioUOTPermiso UP ON UP.usuario_uot_id=UU.usuario_uot_id
                JOIN seg.Permiso P ON P.permiso_id=UP.permiso_id AND P.codigo=?
                WHERE UU.usuario_id=? AND UU.uot_id=? AND UU.estado=1 AND UU.fecha_hasta IS NULL
                  AND UU.fecha_desde<=SYSUTCDATETIME()
                  AND UP.estado=1 AND UP.permitido=0
                  AND UP.fecha_desde<=SYSUTCDATETIME()
                  AND (UP.fecha_hasta IS NULL OR UP.fecha_hasta>SYSUTCDATETIME())
                """,Integer.class,code,user,uot);
            throw new IllegalStateException("Permiso no efectivo para cuenta de prueba: "+code
                +" [usuarioId="+user+", uotId="+uot+", vinculosVigentes="+asignaciones
                +", rolesQueOtorgan="+roles+", denegaciones="+denegacion+"]");
        }
    }
}
