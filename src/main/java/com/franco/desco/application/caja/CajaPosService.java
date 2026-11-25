package com.franco.desco.application.caja;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Caja física reutilizable; CajaSesion identifica cada turno de operación. */
@Service
public class CajaPosService {
    private final JdbcTemplate jdbc;
    private final FiscalReceiptService fiscal;
    private final CajaArqueoRepository arqueos;
    private final tools.jackson.databind.json.JsonMapper json;
    public CajaPosService(JdbcTemplate jdbc, FiscalReceiptService fiscal,
                          CajaArqueoRepository arqueos, tools.jackson.databind.json.JsonMapper json) {
        this.jdbc=jdbc; this.fiscal=fiscal; this.arqueos=arqueos; this.json=json;
    }

    public record Caja(Long cajaId, Long uotId, String codigo, String nombre,
                       Long sesionId, Long operadorId, String estado, BigDecimal saldoInicial, boolean activa) {}
    public record Sesion(Long sesionId, Long cajaId, Long uotId, String caja,
                         Long usuarioAperturaId, Long operadorId, String estado,
                         String fechaApertura, String fechaCierre, BigDecimal saldoInicial,
                         BigDecimal saldoEsperado, BigDecimal saldoDeclarado, BigDecimal diferencia,
                         String observacionApertura, String observacionCierre, String operadorNombre) {}
    public record Resultado(Long id, String mensaje) {}
    public record Operador(Long usuarioId, String nombreUsuario, String nombreCompleto) {}
    public record Evidencia(Long archivoId,Long sesionId,String fase,String nombre,String fecha) {}
    public record Cierre(Long sesionId, BigDecimal saldoEsperado, BigDecimal saldoDeclarado,
                         BigDecimal diferencia) {}
    public record Reporte(String periodo, Long cantidad, BigDecimal vendido,
                          BigDecimal cobrado, BigDecimal efectivo) {}
    public record MovimientoDetalle(Long movimientoId,Long sesionId,String tipo,BigDecimal importe,
                                    String motivo,Long usuarioId,String fecha,String usuarioNombre) {}
    public record AsignacionDetalle(Long asignacionId,Long sesionId,Long anteriorId,Long nuevoId,
                                      Long responsableId,String fecha,String anteriorNombre,String nuevoNombre) {}
    public record VentaTurno(Long ventaId,Long sesionId,String fecha,String estado,
                             BigDecimal total,BigDecimal cobrado) {}
    public record CajaDetalle(Caja caja,List<Sesion> sesiones,List<MovimientoDetalle> movimientos,
                              List<AsignacionDetalle> asignaciones,List<VentaTurno> ventas,
                              List<Evidencia> evidencias) {}
    public record ArqueoMetodo(String codigo, String nombre, BigDecimal total) {}
    public record ArqueoPago(String codigo, String nombre, BigDecimal importe) {}
    public record ArqueoVenta(Long ventaId, String fecha, String estado, BigDecimal total,
                              List<ArqueoPago> pagos) {}
    public record Arqueo(Long sesionId, Long cajaId, String caja, String uotNombre,
                         String estado, String fechaApertura, String fechaCierre, Long operadorId,
                         BigDecimal saldoInicial, BigDecimal efectivo, BigDecimal otrosMedios,
                         BigDecimal ingresos, BigDecimal egresos, BigDecimal ventasEntregadas,
                         BigDecimal totalCobrado, BigDecimal saldoEsperado, BigDecimal saldoDeclarado,
                         BigDecimal diferencia, String observacion, Long ventasPendientes,
                         List<ArqueoMetodo> metodos, List<ArqueoVenta> ventas) {}
    public record Comprobante(Long ventaId, Long uotId, String uotCodigo, String uotNombre,
             String fecha, String cliente, String documento, String moneda, BigDecimal subtotal,
             BigDecimal impuesto, BigDecimal total, String estado, String numeroInterno,
             String estadoSunat, List<Map<String,Object>> lineas,
             String tipoDocumento, String serie, Long numero, String emisorRuc,
             String emisorRazonSocial, String emisorDireccion, String atendidoPor, String qrContenido) {}

    public static final class Regla extends RuntimeException {
        public Regla(String mensaje) { super(mensaje); }
    }
    private void require(boolean condition, String message) { if(!condition) throw new Regla(message); }
    private boolean permitted(long usuario, long uot, String permiso) {
        Integer value=jdbc.queryForObject("SELECT CONVERT(INT,seg.FN_Usuario_TienePermisoUOT(?,?,?))",
                Integer.class,usuario,uot,permiso);
        return value!=null && value==1;
    }
    private void authorize(long usuario,long uot,String permiso) {
        require(permitted(usuario,uot,permiso),"No tiene autorización de "+permiso+" para la UOT seleccionada.");
    }
    private void horarioVigente(long usuario,long uot) {
        Integer vigente=jdbc.queryForObject("SELECT CONVERT(INT,comercial.FN_Pos_HorarioVigente(?,?))",
                Integer.class,usuario,uot);
        require(vigente!=null && vigente==1,"No tienes un horario vigente para esta operación.");
    }
    private void operadorActivo(long usuario,long uot,long sesion) {
        Long asignado=jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM comercial.CajaSesionOperador A
          JOIN comercial.CajaSesion S ON S.caja_sesion_id=A.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE A.usuario_id=? AND A.caja_sesion_id=? AND A.activo=1
            AND S.estado='ABIERTA' AND C.estado=1 AND C.uot_id=?
          """,Long.class,usuario,sesion,uot);
        require(asignado!=null && asignado==1,"No estás asignado a esta caja.");
    }
    private static BigDecimal nonNegative(BigDecimal monto) {
        if(monto==null || monto.signum()<0 || monto.scale()>4) throw new Regla("Importe no válido.");
        return monto;
    }

    @Transactional(readOnly=true)
    public List<Caja> cajas(long usuario,long uot,boolean incluirInactivas) {
        authorize(usuario,uot,"CAJAS_LISTAR");
        if(incluirInactivas) authorize(usuario,uot,"CAJAS_SUPERVISAR");
        return jdbc.query("""
            SELECT C.caja_id,C.uot_id,C.codigo,C.nombre,S.caja_sesion_id,S.usuario_operador_id,
                   COALESCE(S.estado,'DISPONIBLE') estado,S.saldo_inicial,C.estado activa
            FROM comercial.CajaPOS C
            OUTER APPLY(SELECT TOP(1) A.caja_sesion_id,A.usuario_operador_id,A.estado,A.saldo_inicial
              FROM comercial.CajaSesion A WHERE A.caja_id=C.caja_id AND A.estado='ABIERTA') S
            WHERE C.uot_id=? AND (?=1 OR C.estado=1) ORDER BY C.estado DESC,C.nombre,C.caja_id
            """,(rs,n)->new Caja(rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getString(4),
                    (Long)rs.getObject(5),(Long)rs.getObject(6),rs.getString(7),rs.getBigDecimal(8),rs.getBoolean(9)),uot,incluirInactivas?1:0);
    }

    public record CajaDisponible(Long cajaId,String codigo,String nombre) {}
    @Transactional(readOnly=true)
    public List<CajaDisponible> disponibles(long usuario,long uot) {
        authorize(usuario,uot,"CAJAS_ABRIR");
        return jdbc.query("""
          SELECT C.caja_id,C.codigo,C.nombre FROM comercial.CajaPOS C
          WHERE C.uot_id=? AND C.estado=1
            AND NOT EXISTS(SELECT 1 FROM comercial.CajaSesion S
                           WHERE S.caja_id=C.caja_id AND S.estado='ABIERTA')
          ORDER BY C.codigo
          """,(rs,n)->new CajaDisponible(rs.getLong(1),rs.getString(2),rs.getString(3)),uot);
    }

    @Transactional(readOnly=true)
    public List<Operador> operadores(long usuario,long uot) {
        authorize(usuario,uot,"CAJAS_LISTAR");
        return jdbc.query("""
          SELECT U.usuario_id,U.nombre_usuario,
            CONCAT(P.nombres,' ',P.apellido_paterno,' ',COALESCE(P.apellido_materno,'')) nombreCompleto
          FROM seg.Usuario U JOIN org.Persona P ON P.persona_id=U.persona_id
          JOIN seg.UsuarioUOT UU ON UU.usuario_id=U.usuario_id
          WHERE UU.uot_id=? AND U.estado=1 AND UU.estado=1 AND UU.fecha_hasta IS NULL
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'POS_OPERAR')=1
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_ABRIR')=1
            AND seg.FN_Usuario_TienePermisoUOT(U.usuario_id,?,'CAJAS_CERRAR')=1
          GROUP BY U.usuario_id,U.nombre_usuario,P.nombres,P.apellido_paterno,P.apellido_materno
          ORDER BY U.nombre_usuario
          """,(rs,n)->new Operador(rs.getLong(1),rs.getString(2),rs.getString(3)),uot,uot,uot,uot);
    }

    @Transactional(readOnly=true)
    public Sesion activa(long usuario,long uot) {
        authorize(usuario,uot,"POS_OPERAR");
        return jdbc.query("""
          SELECT TOP(1) S.caja_sesion_id,S.caja_id,C.uot_id,C.nombre,S.usuario_apertura_id,
            S.usuario_operador_id,S.estado,CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_apertura),126),
            CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_cierre),126),S.saldo_inicial,S.saldo_esperado,
            S.saldo_declarado,S.diferencia,S.observacion_apertura,S.observacion_cierre,
            seg.FN_Usuario_NombreCompleto(S.usuario_operador_id) operadorNombre
          FROM comercial.CajaSesion S JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE C.uot_id=? AND C.estado=1 AND S.estado='ABIERTA'
            AND EXISTS(SELECT 1 FROM comercial.CajaSesionOperador O
              WHERE O.caja_sesion_id=S.caja_sesion_id AND O.usuario_id=? AND O.activo=1)
            AND comercial.FN_Pos_HorarioVigente(?,?)=1
          ORDER BY S.fecha_apertura DESC,S.caja_sesion_id DESC
          """,(rs,n)->sesion(rs),uot,usuario,usuario,uot).stream().findFirst().orElse(null);
    }

    @Transactional(readOnly=true)
    public List<Sesion> sesiones(long usuario,long uot) {
        authorize(usuario,uot,"CAJAS_LISTAR");
        return jdbc.query("""
          SELECT S.caja_sesion_id,S.caja_id,C.uot_id,C.nombre,S.usuario_apertura_id,
            S.usuario_operador_id,S.estado,CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_apertura),126),
            CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_cierre),126),S.saldo_inicial,S.saldo_esperado,
            S.saldo_declarado,S.diferencia,S.observacion_apertura,S.observacion_cierre,
            seg.FN_Usuario_NombreCompleto(S.usuario_operador_id) operadorNombre
          FROM comercial.CajaSesion S JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE C.uot_id=? ORDER BY S.fecha_apertura DESC,S.caja_sesion_id DESC
          """,(rs,n)->sesion(rs),uot);
    }
    private Sesion sesion(java.sql.ResultSet rs)throws java.sql.SQLException {
        return new Sesion(rs.getLong(1),rs.getLong(2),rs.getLong(3),rs.getString(4),
                rs.getLong(5),rs.getLong(6),rs.getString(7),rs.getString(8),rs.getString(9),
                rs.getBigDecimal(10),rs.getBigDecimal(11),rs.getBigDecimal(12),rs.getBigDecimal(13),
                rs.getString(14),rs.getString(15),rs.getString(16));
    }

    @Transactional
    public Resultado crear(long usuario,long uot,String nombre) {
        authorize(usuario,uot,"CAJAS_CREAR");
        String label=nombre==null?"":nombre.trim();
        require(label.length()>=3 && label.length()<=120,"Ingrese un nombre válido.");
        require(Boolean.TRUE.equals(jdbc.queryForObject("SELECT CONVERT(BIT,CASE WHEN EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=? AND estado=1) THEN 1 ELSE 0 END)",Boolean.class,uot)),"Unidad territorial no disponible.");
        // Temporal único dentro de la misma transacción. El código definitivo deriva del ID de BD.
        String temporal="TMP-"+UUID.randomUUID().toString().replace("-", "").substring(0,24);
        Long id=jdbc.queryForObject("""
          INSERT comercial.CajaPOS(uot_id,codigo,nombre,usuario_creacion_id)
          OUTPUT INSERTED.caja_id VALUES(?,?,?,?)
          """,Long.class,uot,temporal,label,usuario);
        require(id!=null,"No se pudo crear la caja.");
        long consecutivo=id;
        String codigo;
        do {
            String numero=Long.toString(consecutivo);
            codigo="CAJA-"+(numero.length()<4?"0".repeat(4-numero.length()):"")+numero;
            require(codigo.length()<=30,"No se pudo generar el código de caja.");
            Boolean ocupado=jdbc.queryForObject("""
              SELECT CONVERT(BIT,CASE WHEN EXISTS(
                SELECT 1 FROM comercial.CajaPOS WITH(UPDLOCK,HOLDLOCK)
                WHERE uot_id=? AND codigo=?) THEN 1 ELSE 0 END)
              """,Boolean.class,uot,codigo);
            if(!Boolean.TRUE.equals(ocupado)) break;
            consecutivo++;
        } while(true);
        jdbc.update("UPDATE comercial.CajaPOS SET codigo=? WHERE caja_id=?",codigo,id);
        return new Resultado(id,"Caja creada correctamente.");
    }

    @Transactional
    public Resultado editar(long usuario,long uot,long id,String nombre) {
        authorize(usuario,uot,"CAJAS_EDITAR");
        String label=nombre==null?"":nombre.trim();
        require(label.length()>=3 && label.length()<=120,"Ingrese un nombre válido.");
        int updated=jdbc.update("""
          UPDATE comercial.CajaPOS SET nombre=?
          WHERE caja_id=? AND uot_id=? AND estado=1
            AND NOT EXISTS(SELECT 1 FROM comercial.CajaSesion WHERE caja_id=? AND estado='ABIERTA')
          """,label,id,uot,id);
        require(updated==1,"La caja no está disponible para editar.");
        return new Resultado(id,"Caja actualizada.");
    }

    @Transactional
    public Resultado retirar(long usuario,long uot,long id) {
        authorize(usuario,uot,"CAJAS_RETIRAR");
        int changed=jdbc.update("""
          UPDATE comercial.CajaPOS SET estado=0 WHERE caja_id=? AND uot_id=? AND estado=1
          AND NOT EXISTS(SELECT 1 FROM comercial.CajaSesion WHERE caja_id=? AND estado='ABIERTA')
          """,id,uot,id);
        require(changed==1,"La caja no está disponible o tiene un turno abierto.");
        return new Resultado(id,"Caja deshabilitada. Su historial permanece registrado.");
    }

    @Transactional(readOnly=true)
    public CajaDetalle detalle(long usuario,long uot,long id) {
        authorize(usuario,uot,"CAJAS_SUPERVISAR");
        var cajas=jdbc.query("""
          SELECT C.caja_id,C.uot_id,C.codigo,C.nombre,S.caja_sesion_id,S.usuario_operador_id,
                 COALESCE(S.estado,'DISPONIBLE'),S.saldo_inicial,C.estado activa
          FROM comercial.CajaPOS C
          OUTER APPLY(SELECT TOP(1) A.caja_sesion_id,A.usuario_operador_id,A.estado,A.saldo_inicial
              FROM comercial.CajaSesion A WHERE A.caja_id=C.caja_id AND A.estado='ABIERTA') S
          WHERE C.caja_id=? AND C.uot_id=?
          """,(rs,n)->new Caja(rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getString(4),
                 (Long)rs.getObject(5),(Long)rs.getObject(6),rs.getString(7),rs.getBigDecimal(8),rs.getBoolean(9)),id,uot);
        require(!cajas.isEmpty(),"Caja no encontrada en la UOT.");
        var turnos=jdbc.query("""
          SELECT S.caja_sesion_id,S.caja_id,C.uot_id,C.nombre,S.usuario_apertura_id,
            S.usuario_operador_id,S.estado,CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_apertura),126),
            CONVERT(VARCHAR(19),DATEADD(HOUR,-5,S.fecha_cierre),126),S.saldo_inicial,S.saldo_esperado,
            S.saldo_declarado,S.diferencia,S.observacion_apertura,S.observacion_cierre,
            seg.FN_Usuario_NombreCompleto(S.usuario_operador_id) operadorNombre
          FROM comercial.CajaSesion S JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE C.caja_id=? AND C.uot_id=? ORDER BY S.fecha_apertura DESC,S.caja_sesion_id DESC
          """,(rs,n)->sesion(rs),id,uot);
        var movimientos=jdbc.query("""
          SELECT M.caja_movimiento_id,M.caja_sesion_id,M.tipo,M.importe,M.motivo,M.usuario_id,
            CONVERT(VARCHAR(19),DATEADD(HOUR,-5,M.fecha_hora),126),
            seg.FN_Usuario_NombreCompleto(M.usuario_id) usuarioNombre
          FROM comercial.CajaMovimiento M JOIN comercial.CajaSesion S ON S.caja_sesion_id=M.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE C.caja_id=? AND C.uot_id=? ORDER BY M.fecha_hora DESC,M.caja_movimiento_id DESC
          """,(rs,n)->new MovimientoDetalle(rs.getLong(1),rs.getLong(2),rs.getString(3),
                  rs.getBigDecimal(4),rs.getString(5),rs.getLong(6),rs.getString(7),rs.getString(8)),id,uot);
        var asignaciones=jdbc.query("""
          SELECT A.asignacion_id,A.caja_sesion_id,A.usuario_anterior_id,A.usuario_nuevo_id,
            A.usuario_responsable_id,CONVERT(VARCHAR(19),DATEADD(HOUR,-5,A.fecha_hora),126),
            seg.FN_Usuario_NombreCompleto(A.usuario_anterior_id) anteriorNombre,
            seg.FN_Usuario_NombreCompleto(A.usuario_nuevo_id) nuevoNombre
          FROM comercial.CajaAsignacion A JOIN comercial.CajaSesion S ON S.caja_sesion_id=A.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE C.caja_id=? AND C.uot_id=? ORDER BY A.fecha_hora DESC,A.asignacion_id DESC
          """,(rs,n)->new AsignacionDetalle(rs.getLong(1),rs.getLong(2),rs.getLong(3),
                  rs.getLong(4),rs.getLong(5),rs.getString(6),rs.getString(7),rs.getString(8)),id,uot);
        var ventas=jdbc.query("""
          SELECT V.venta_id,V.caja_sesion_id,
            CONVERT(VARCHAR(19),DATEADD(HOUR,-5,V.fecha_hora),126),V.estado_venta,V.total,
            COALESCE(P.pagado,0)
          FROM comercial.Venta V JOIN comercial.CajaSesion S ON S.caja_sesion_id=V.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          OUTER APPLY(SELECT SUM(PV.importe) pagado FROM comercial.PagoVenta PV
              WHERE PV.venta_id=V.venta_id AND PV.estado=1 AND PV.estado_pago='CONFIRMADO') P
          WHERE C.caja_id=? AND C.uot_id=? ORDER BY V.fecha_hora DESC,V.venta_id DESC
          """,(rs,n)->new VentaTurno(rs.getLong(1),rs.getLong(2),rs.getString(3),
                  rs.getString(4),rs.getBigDecimal(5),rs.getBigDecimal(6)),id,uot);
        List<Evidencia> evidencias=jdbc.query("""
          SELECT E.archivo_id,E.caja_sesion_id,E.fase,A.nombre_original,
                 CONVERT(VARCHAR(19),DATEADD(HOUR,-5,E.fecha_registro),126)
          FROM comercial.CajaEvidencia E JOIN archivo.Archivo A ON A.archivo_id=E.archivo_id
          JOIN comercial.CajaSesion S ON S.caja_sesion_id=E.caja_sesion_id
          WHERE S.caja_id=? AND A.estado=1 ORDER BY E.fecha_registro DESC,E.caja_evidencia_id DESC
          """,(rs,n)->new Evidencia(rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getString(4),rs.getString(5)),id);
        return new CajaDetalle(cajas.getFirst(),turnos,movimientos,asignaciones,ventas,evidencias);
    }

    @Transactional
    public Resultado abrir(long usuario,long uot,long caja,BigDecimal inicial,String observacion,List<Long> archivos) {
        authorize(usuario,uot,"CAJAS_ABRIR");
        nonNegative(inicial);
        authorize(usuario,uot,"POS_OPERAR");
        horarioVigente(usuario,uot);
        // El operador lo determina exclusivamente la identidad autenticada.
        long operador=usuario;
        require(observacion==null || observacion.length()<=500,"Observación demasiado extensa.");
        var active=jdbc.query("""
           SELECT C.caja_id FROM comercial.CajaPOS C WITH(UPDLOCK,HOLDLOCK)
           WHERE C.caja_id=? AND C.uot_id=? AND C.estado=1
           """,(rs,n)->rs.getLong(1),caja,uot);
        require(!active.isEmpty(),"La caja no pertenece a esta UOT o está deshabilitada.");
        Long existing=jdbc.queryForObject("SELECT COUNT_BIG(1) FROM comercial.CajaSesion WITH(UPDLOCK,HOLDLOCK) WHERE caja_id=? AND estado='ABIERTA'",Long.class,caja);
        require(existing!=null && existing==0,"La caja ya está abierta.");
        Long occupied=jdbc.queryForObject("SELECT COUNT_BIG(1) FROM comercial.CajaSesionOperador WITH(UPDLOCK,HOLDLOCK) WHERE usuario_id=? AND activo=1",Long.class,operador);
        require(occupied!=null && occupied==0,"El operador ya tiene una caja abierta.");
        Long id=jdbc.queryForObject("""
          INSERT comercial.CajaSesion(caja_id,usuario_apertura_id,usuario_operador_id,saldo_inicial,observacion_apertura)
          OUTPUT INSERTED.caja_sesion_id VALUES(?,?,?,?,?)
          """,Long.class,caja,usuario,operador,inicial,observacion);
        require(id!=null,"No se pudo abrir la caja.");
        jdbc.update("INSERT comercial.CajaSesionOperador(caja_sesion_id,usuario_id,usuario_asignacion_id) VALUES(?,?,?)",
                id,usuario,usuario);
        vincularEvidencias(usuario,uot,id,"APERTURA",archivos);
        return new Resultado(id,"Caja abierta correctamente.");
    }

    @Transactional
    public Resultado asignar(long usuario,long uot,long sesion,long operador) {
        authorize(usuario,uot,"CAJAS_ASIGNAR");
        authorize(operador,uot,"POS_OPERAR");
        authorize(operador,uot,"CAJAS_ABRIR");
        authorize(operador,uot,"CAJAS_CERRAR");
        horarioVigente(operador,uot);
        var rows=jdbc.query("""
          SELECT S.caja_sesion_id FROM comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK)
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE S.caja_sesion_id=? AND C.uot_id=? AND C.estado=1 AND S.estado='ABIERTA'
          """,(rs,n)->rs.getLong(1),sesion,uot);
        require(!rows.isEmpty(),"La caja no está abierta.");
        Long previo=jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM comercial.CajaSesionOperador WITH(UPDLOCK,HOLDLOCK)
          WHERE usuario_id=? AND activo=1
          """,Long.class,operador);
        if(previo!=null && previo>0) {
            Long esta=jdbc.queryForObject("""
              SELECT COUNT_BIG(*) FROM comercial.CajaSesionOperador
              WHERE caja_sesion_id=? AND usuario_id=? AND activo=1
              """,Long.class,sesion,operador);
            require(esta!=null && esta==1,"El empleado ya está asignado a otra caja.");
            return new Resultado(sesion,"El empleado ya está asignado.");
        }
        int changed=jdbc.update("""
          UPDATE comercial.CajaSesionOperador SET activo=1,fecha_retiro=NULL,
             usuario_retiro_id=NULL,fecha_asignacion=SYSUTCDATETIME(),usuario_asignacion_id=?
          WHERE caja_sesion_id=? AND usuario_id=? AND activo=0
          """,usuario,sesion,operador);
        if(changed==0) jdbc.update("""
          INSERT comercial.CajaSesionOperador(caja_sesion_id,usuario_id,usuario_asignacion_id)
          VALUES(?,?,?)
          """,sesion,operador,usuario);
        jdbc.update("""
          INSERT comercial.CajaAsignacion(caja_sesion_id,usuario_anterior_id,usuario_nuevo_id,usuario_responsable_id)
          SELECT ?,S.usuario_operador_id,?,? FROM comercial.CajaSesion S WHERE S.caja_sesion_id=?
          """,sesion,operador,usuario,sesion);
        return new Resultado(sesion,"Empleado agregado a la caja.");
    }

    @Transactional(readOnly=true)
    public List<Operador> asignados(long usuario,long uot,long sesion) {
        authorize(usuario,uot,"CAJAS_LISTAR");
        return jdbc.query("""
          SELECT U.usuario_id,U.nombre_usuario,
             LTRIM(RTRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))))
          FROM comercial.CajaSesionOperador A JOIN comercial.CajaSesion S ON S.caja_sesion_id=A.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          JOIN seg.Usuario U ON U.usuario_id=A.usuario_id
          JOIN org.Persona P ON P.persona_id=U.persona_id
          WHERE A.caja_sesion_id=? AND C.uot_id=? AND A.activo=1
          ORDER BY A.fecha_asignacion,A.usuario_id
          """,(rs,n)->new Operador(rs.getLong(1),rs.getString(2),rs.getString(3)),sesion,uot);
    }

    @Transactional
    public Resultado quitar(long usuario,long uot,long sesion,long operador) {
        authorize(usuario,uot,"CAJAS_ASIGNAR");
        var locked=jdbc.query("""
          SELECT S.usuario_apertura_id FROM comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK)
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE S.caja_sesion_id=? AND C.uot_id=? AND C.estado=1 AND S.estado='ABIERTA'
          """,(rs,n)->rs.getLong(1),sesion,uot);
        require(!locked.isEmpty(),"La caja no está abierta.");
        require(locked.getFirst()!=operador,"No puedes retirar a quien abrió la caja.");
        Long pendientes=jdbc.queryForObject("""
          SELECT COUNT_BIG(*) FROM comercial.Venta WHERE caja_sesion_id=? AND vendedor_usuario_id=?
          AND estado=1 AND estado_venta NOT IN('ANULADA','ENTREGADA')
          """,Long.class,sesion,operador);
        require(pendientes!=null && pendientes==0,"Este empleado tiene ventas pendientes.");
        int updated=jdbc.update("""
          UPDATE comercial.CajaSesionOperador SET activo=0,fecha_retiro=SYSUTCDATETIME(),usuario_retiro_id=?
          WHERE caja_sesion_id=? AND usuario_id=? AND activo=1
          """,usuario,sesion,operador);
        require(updated==1,"El empleado no está asignado a esta caja.");
        return new Resultado(sesion,"Empleado retirado de la caja.");
    }

    @Transactional
    public Resultado movimiento(long usuario,long uot,long sesion,String tipo,BigDecimal importe,
                               String motivo,UUID clave) {
        authorize(usuario,uot,"CAJAS_MOVIMIENTOS");
        require(importe!=null && importe.signum()>0 && importe.scale()<=4,"El importe debe ser positivo.");
        require(tipo.equals("INGRESO") || tipo.equals("EGRESO"),"Tipo de movimiento no válido.");
        require(motivo!=null && motivo.trim().length()>=5 && motivo.trim().length()<=300,"El motivo debe tener entre 5 y 300 caracteres.");
        require(clave!=null,"Clave de idempotencia obligatoria.");
        var previous=jdbc.query("SELECT caja_movimiento_id,caja_sesion_id FROM comercial.CajaMovimiento WHERE clave_idempotencia=?",
                (rs,n)->List.of(rs.getLong(1),rs.getLong(2)),clave);
        if(!previous.isEmpty()) {
            require(previous.getFirst().get(1)==sesion,"La clave ya pertenece a otra sesión.");
            return new Resultado(previous.getFirst().get(0),"Movimiento ya registrado.");
        }
        require(!jdbc.query("""
          SELECT S.caja_sesion_id FROM comercial.CajaSesion S WITH(UPDLOCK,HOLDLOCK)
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE S.caja_sesion_id=? AND C.uot_id=? AND S.estado='ABIERTA'
          """,(rs,n)->rs.getLong(1),sesion,uot).isEmpty(),"Sesión no disponible.");
        if(!permitted(usuario,uot,"CAJAS_SUPERVISAR")) {
            horarioVigente(usuario,uot);
            operadorActivo(usuario,uot,sesion);
        }
        Long id=jdbc.queryForObject("""
          INSERT comercial.CajaMovimiento(caja_sesion_id,tipo,importe,motivo,usuario_id,clave_idempotencia)
          OUTPUT INSERTED.caja_movimiento_id VALUES(?,?,?,?,?,?)
          """,Long.class,sesion,tipo,importe,motivo.trim(),usuario,clave);
        return new Resultado(id,"Movimiento de caja registrado.");
    }

    @Transactional(readOnly = true)
    public Arqueo arqueo(long usuario, long uot, long sesion) {
        return ejecutarArqueo("CONSULTAR", usuario, uot, sesion, null, null);
    }

    private Arqueo ejecutarArqueo(String accion, long usuario, long uot, long sesion,
                                 BigDecimal declarado, String observacion) {
        var resultado = arqueos.ejecutar(accion, usuario, uot, sesion, declarado, observacion);
        if (!resultado.exitoso()) throw new Regla(resultado.mensaje());
        return json.readValue(resultado.json(), Arqueo.class);
    }

    @Transactional
    public Cierre cerrar(long usuario, long uot, long sesion, BigDecimal declarado,
                         String observacion, List<Long> archivos) {
        authorize(usuario, uot, "CAJAS_CERRAR");
        nonNegative(declarado);
        require(declarado.scale() <= 2, "El importe contado debe tener dos decimales como máximo.");
        Arqueo balance = ejecutarArqueo("CERRAR", usuario, uot, sesion, declarado, observacion);
        vincularEvidencias(usuario, uot, sesion, "CIERRE", archivos);
        return new Cierre(sesion, balance.saldoEsperado(), balance.saldoDeclarado(), balance.diferencia());
    }

    private void vincularEvidencias(long usuario,long uot,long sesion,String fase,List<Long> archivos) {
        if(archivos==null||archivos.isEmpty())return;
        require(archivos.size()<=5 && archivos.stream().allMatch(java.util.Objects::nonNull)
                && archivos.stream().allMatch(id->id>0)
                && archivos.stream().distinct().count()==archivos.size(),"Adjunte hasta cinco imágenes distintas.");
        for(Long archivo:archivos) {
            Integer count=jdbc.queryForObject("""
              SELECT COUNT(*) FROM archivo.Archivo A
              WHERE A.archivo_id=? AND A.uot_id=? AND A.usuario_id=? AND A.estado=1
                AND A.proveedor_almacenamiento='LOCAL'
                AND A.mime_type IN('image/jpeg','image/png','image/webp')
                AND A.tamano_bytes BETWEEN 1 AND 8388608
                AND NOT EXISTS(SELECT 1 FROM comercial.CajaEvidencia E WHERE E.archivo_id=A.archivo_id)
              """,Integer.class,archivo,uot,usuario);
            require(count!=null && count==1,"Una imagen no está disponible.");
            jdbc.update("INSERT comercial.CajaEvidencia(caja_sesion_id,archivo_id,fase,usuario_registro_id) VALUES(?,?,?,?)",
                    sesion,archivo,fase,usuario);
        }
    }

    @Transactional(readOnly=true)
    public List<Reporte> reporte(long usuario,long uot,String agrupacion,String desde,String hasta) {
        authorize(usuario,uot,"VENTAS_REPORTES");
        require("DIA".equals(agrupacion)||"MES".equals(agrupacion),"Seleccione un periodo válido.");
        java.time.LocalDate inicio,fin;
        try { inicio=java.time.LocalDate.parse(desde);fin=java.time.LocalDate.parse(hasta); }
        catch(RuntimeException ex) {throw new Regla("Seleccione fechas válidas.");}
        require(!fin.isBefore(inicio) && !fin.isAfter(inicio.plusYears(2)),"El rango de fechas no es válido.");
        // Agrupar pagos una sola vez antes del LEFT JOIN; no sumar de nuevo cada detalle.
        // Limitar al ámbito autorizado. Usar fechas UTC delimitadas para Lima.
        return jdbc.query("""
          WITH Pagos AS (
             SELECT PV.venta_id,
               SUM(CASE WHEN PV.estado=1 AND PV.estado_pago='CONFIRMADO' THEN PV.importe ELSE 0 END) cobrado,
               SUM(CASE WHEN PV.estado=1 AND PV.estado_pago='CONFIRMADO' AND MP.codigo='EFECTIVO'
                        THEN PV.importe ELSE 0 END) efectivo
             FROM comercial.PagoVenta PV
             JOIN comercial.MetodoPago MP ON MP.metodo_pago_id=PV.metodo_pago_id
             GROUP BY PV.venta_id
          ), Datos AS (
            SELECT CASE WHEN ?='MES'
              THEN CONVERT(CHAR(7),DATEADD(HOUR,-5,V.fecha_hora),126)
              ELSE CONVERT(CHAR(10),DATEADD(HOUR,-5,V.fecha_hora),126) END periodo,
              V.total,ISNULL(P.cobrado,0) cobrado,ISNULL(P.efectivo,0) efectivo
            FROM comercial.Venta V LEFT JOIN Pagos P ON P.venta_id=V.venta_id
            WHERE V.uot_id=? AND V.estado=1 AND V.estado_venta='ENTREGADA'
              AND V.fecha_hora>=? AND V.fecha_hora<?
          )
          SELECT periodo,COUNT_BIG(*) cantidad,ISNULL(SUM(total),0) vendido,
            ISNULL(SUM(cobrado),0) cobrado,ISNULL(SUM(efectivo),0) efectivo
          FROM Datos GROUP BY periodo ORDER BY periodo
          """,(rs,n)->new Reporte(rs.getString(1),rs.getLong(2),rs.getBigDecimal(3),rs.getBigDecimal(4),rs.getBigDecimal(5)),
          agrupacion,uot,java.sql.Timestamp.valueOf(inicio.atStartOfDay().plusHours(5)),
          java.sql.Timestamp.valueOf(fin.plusDays(1).atStartOfDay().plusHours(5)));
    }

    @Transactional
    public Resultado editarObservacionVenta(long usuario,long uot,long venta,String nota) {
        authorize(usuario,uot,"VENTAS_EDITAR");
        require(nota!=null && !nota.trim().isEmpty() && nota.trim().length()<=500,
                "Ingrese una observación válida.");
        Integer allowed=jdbc.queryForObject("""
          SELECT COUNT(*) FROM comercial.Venta V WITH(UPDLOCK,HOLDLOCK)
          JOIN comercial.CajaSesion S ON S.caja_sesion_id=V.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE V.venta_id=? AND V.uot_id=? AND C.uot_id=? AND V.estado=1
            AND V.estado_venta NOT IN('ENTREGADA','ANULADA')
            AND NOT EXISTS(SELECT 1 FROM comercial.PagoVenta P WHERE P.venta_id=V.venta_id
                           AND P.estado=1 AND P.estado_pago='CONFIRMADO')
            AND (seg.FN_Usuario_TienePermisoUOT(?,?,'VENTAS_TODAS_VER')=1
                 OR (V.vendedor_usuario_id=? AND S.usuario_operador_id=? AND S.estado='ABIERTA'
                  AND CONVERT(DATE,DATEADD(HOUR,-5,V.fecha_hora))=
                      CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
          """,Integer.class,venta,uot,uot,usuario,uot,usuario,usuario);
        require(allowed!=null && allowed==1,"Esta venta no está disponible para editar.");
        int changed=jdbc.update("""
          UPDATE comercial.Venta SET observacion=? WHERE venta_id=? AND uot_id=? AND estado=1
          """,nota.trim(),venta,uot);
        require(changed==1,"La venta no está disponible.");
        return new Resultado(venta,"Observación actualizada.");
    }

    @Transactional
    public Comprobante comprobante(long usuario,long saleId) {
        var rows=jdbc.query("""
          SELECT V.venta_id,V.uot_id,U.codigo,U.nombre,CONVERT(VARCHAR(19),DATEADD(HOUR,-5,V.fecha_hora),126),
            COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(P.nombres,' ',P.apellido_paterno,' ',COALESCE(P.apellido_materno,'')))) ,''),
                     E.razon_social,N'CLIENTE VARIOS') cliente,
            COALESCE(P.numero_documento,E.ruc,'') documento,V.moneda,V.subtotal,V.impuesto,V.total,V.estado_venta
          FROM comercial.Venta V JOIN org.UOT U ON U.uot_id=V.uot_id
          LEFT JOIN org.Persona P ON P.persona_id=V.cliente_persona_id
          LEFT JOIN org.Empresa E ON E.empresa_id=V.cliente_empresa_id
          WHERE V.venta_id=? AND V.estado=1
          """,(rs,n)->new Object[]{rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getString(4),
              rs.getString(5),rs.getString(6),rs.getString(7),rs.getString(8),
              rs.getBigDecimal(9),rs.getBigDecimal(10),rs.getBigDecimal(11),rs.getString(12)},saleId);
        require(!rows.isEmpty(),"Venta inexistente.");
        Object[] r=rows.getFirst();
        long uot=(Long)r[1];
        boolean all=permitted(usuario,uot,"VENTAS_TODAS_VER");
        Integer propia=jdbc.queryForObject("""
          SELECT COUNT(1) FROM comercial.Venta V
          JOIN comercial.CajaSesion S ON S.caja_sesion_id=V.caja_sesion_id
          JOIN comercial.CajaPOS C ON C.caja_id=S.caja_id
          WHERE V.venta_id=? AND V.uot_id=? AND V.vendedor_usuario_id=?
            AND C.uot_id=V.uot_id
          """,Integer.class,saleId,uot,usuario);
        // La reimpresión de ventas propias permanece disponible después del cierre de caja.
        require(all || (propia!=null && propia>0 &&
                (permitted(usuario,uot,"POS_OPERAR") || permitted(usuario,uot,"COMPROBANTES_VER"))),
                "No tiene permiso para consultar este comprobante.");
        List<Map<String,Object>> lines=jdbc.queryForList("""
          SELECT P.nombre producto,D.cantidad,D.precio_unitario precioUnitario,D.subtotal
          FROM comercial.DetalleVenta D JOIN logistica.Producto P ON P.producto_id=D.producto_id
          WHERE D.venta_id=? AND D.estado=1 ORDER BY D.detalle_venta_id
          """,saleId);
        var info=fiscal.preparar(saleId,uot,(String)r[3],(String)r[4],(String)r[5],(String)r[6],
                (String)r[7],(BigDecimal)r[8],(BigDecimal)r[9],(BigDecimal)r[10],lines);
        return new Comprobante((Long)r[0],uot,(String)r[2],(String)r[3],(String)r[4],
                (String)r[5],(String)r[6],(String)r[7],(BigDecimal)r[8],(BigDecimal)r[9],(BigDecimal)r[10],
                (String)r[11],info.serie()+"-"+String.format("%08d",info.numero()),
                info.estadoFiscal(),lines,info.tipoDocumento(),info.serie(),info.numero(),
                info.emisorRuc(),info.emisorRazonSocial(),info.emisorDireccion(),
                info.atendidoPor(),info.qrContenido());
    }
}
