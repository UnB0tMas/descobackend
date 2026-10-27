package com.franco.desco.adapter.out.sql.sale;

import com.franco.desco.adapter.out.sql.common.SqlIdempotencyCoordinator;
import com.franco.desco.adapter.out.sql.common.SqlProcedureExecutor;
import com.franco.desco.application.sale.SaleCommands;
import com.franco.desco.application.sale.port.out.SalePersistencePort;
import com.franco.desco.application.shared.PersistenceResult;
import com.franco.desco.application.shared.SessionIdentity;
import com.franco.desco.application.uot.port.out.UotPersistencePort;
import com.franco.desco.domain.sale.SaleModels;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.*;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.json.JsonMapper;

import java.sql.Types;
import java.time.LocalDateTime;
import java.util.*;

@Repository
public class SqlServerSalePersistenceAdapter implements SalePersistencePort {
    private static final Long INVALID_SCOPE = Long.MIN_VALUE;
    private final JdbcTemplate jdbc;
    private final SqlProcedureExecutor procedures;
    private final UotPersistencePort uot;
    private final JsonMapper json;
    private final SqlIdempotencyCoordinator idempotency;

    public SqlServerSalePersistenceAdapter(JdbcTemplate jdbc, SqlProcedureExecutor procedures, UotPersistencePort uot,
                                           JsonMapper json, SqlIdempotencyCoordinator idempotency) {
        this.jdbc=jdbc;this.procedures=procedures;this.uot=uot;this.json=json;this.idempotency=idempotency;
    }

    @Override
    public PersistenceResult<List<SaleModels.Summary>> list(SessionIdentity identity, Long requestedUot, String status) {
        Long filter=scope(identity,requestedUot,"VENTAS_LISTAR");
        if(filter==INVALID_SCOPE)return PersistenceResult.error("Seleccione una UOT autorizada.");
        String normalized=status==null||status.isBlank()?null:status.trim().toUpperCase(Locale.ROOT);
        try{
            List<SaleModels.Summary> values=jdbc.query("""
                    SELECT S.venta_id,S.uot_id,U.nombre uot_nombre,S.almacen_id,A.nombre almacen,V.fecha_reserva_hasta,S.fecha_hora,S.estado_venta,S.moneda,S.total,S.pagado,S.saldo,
                           COALESCE(NULLIF(CONCAT(P.nombres,' ',P.apellido_paterno,' ',ISNULL(P.apellido_materno,'')),'  '),E.razon_social,N'Público general') cliente,
                           V.vendedor_usuario_id
                    FROM comercial.VW_VentaSaldo S
                    JOIN comercial.Venta V ON V.venta_id=S.venta_id
                    JOIN org.UOT U ON U.uot_id=S.uot_id JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id
                    LEFT JOIN org.Persona P ON P.persona_id=V.cliente_persona_id LEFT JOIN org.Empresa E ON E.empresa_id=V.cliente_empresa_id
                    WHERE V.estado=1
                      AND EXISTS(SELECT 1 FROM seg.UsuarioUOT UU WHERE UU.usuario_id=? AND UU.uot_id=S.uot_id AND UU.estado=1 AND UU.fecha_hasta IS NULL)
                      AND seg.FN_Usuario_TienePermisoUOT(?,S.uot_id,'VENTAS_LISTAR')=1
                      AND (? IS NULL OR S.uot_id=?) AND (? IS NULL OR S.estado_venta=?)
                    ORDER BY S.fecha_hora DESC,S.venta_id DESC
                    """,(rs,n)->summary(rs),identity.usuarioId(),identity.usuarioId(),filter,filter,normalized,normalized);
            return PersistenceResult.ok("Ventas consultadas correctamente.",values);
        }catch(DataAccessException e){return PersistenceResult.error("No se pudieron consultar las ventas.");}
    }

    @Override
    public PersistenceResult<SaleModels.Detail> get(SessionIdentity identity, Long saleId) {
        try{
            List<SaleModels.Summary> headers=jdbc.query("""
                    SELECT S.venta_id,S.uot_id,U.nombre uot_nombre,S.almacen_id,A.nombre almacen,V.fecha_reserva_hasta,S.fecha_hora,S.estado_venta,S.moneda,S.total,S.pagado,S.saldo,
                           COALESCE(NULLIF(CONCAT(P.nombres,' ',P.apellido_paterno,' ',ISNULL(P.apellido_materno,'')),'  '),E.razon_social,N'Público general') cliente,
                           V.vendedor_usuario_id
                    FROM comercial.VW_VentaSaldo S JOIN comercial.Venta V ON V.venta_id=S.venta_id
                    JOIN org.UOT U ON U.uot_id=S.uot_id JOIN logistica.Almacen A ON A.almacen_id=S.almacen_id
                    LEFT JOIN org.Persona P ON P.persona_id=V.cliente_persona_id LEFT JOIN org.Empresa E ON E.empresa_id=V.cliente_empresa_id
                    WHERE S.venta_id=? AND V.estado=1
                    """,(rs,n)->summary(rs),saleId);
            if(headers.isEmpty())return PersistenceResult.error("La venta no está disponible.");
            SaleModels.Summary header=headers.getFirst();
            if(!uot.hasPermission(identity,header.uotId(),"VENTAS_LISTAR"))return PersistenceResult.error("No tiene acceso a la venta seleccionada.");
            List<SaleModels.Line> lines=jdbc.query("""
                    SELECT D.detalle_venta_id,D.producto_id,P.nombre,D.cantidad,D.producto_precio_id,D.precio_unitario,D.descuento_unitario,D.subtotal
                    FROM comercial.DetalleVenta D JOIN logistica.Producto P ON P.producto_id=D.producto_id
                    WHERE D.venta_id=? AND D.estado=1 ORDER BY D.detalle_venta_id
                    """,(rs,n)->new SaleModels.Line(rs.getLong(1),rs.getLong(2),rs.getString(3),rs.getBigDecimal(4),rs.getLong(5),rs.getBigDecimal(6),rs.getBigDecimal(7),rs.getBigDecimal(8)),saleId);
            List<SaleModels.Payment> payments=jdbc.query("""
                    SELECT PV.pago_venta_id,PV.metodo_pago_id,MP.nombre,PV.importe,PV.moneda,PV.numero_operacion,PV.fecha_hora,PV.usuario_id,PV.estado_pago
                    FROM comercial.PagoVenta PV JOIN comercial.MetodoPago MP ON MP.metodo_pago_id=PV.metodo_pago_id
                    WHERE PV.venta_id=? ORDER BY PV.fecha_hora,PV.pago_venta_id
                    """,(rs,n)->new SaleModels.Payment(rs.getLong(1),rs.getInt(2),rs.getString(3),rs.getBigDecimal(4),rs.getString(5),rs.getString(6),dateTime(rs,7),rs.getLong(8),rs.getString(9)),saleId);
            SaleModels.Receipt receipt=receipt(saleId);
            return PersistenceResult.ok("Venta obtenida correctamente.",new SaleModels.Detail(header,lines,payments,receipt));
        }catch(DataAccessException e){return PersistenceResult.error("No se pudo consultar la venta.");}
    }

    @Override
    public PersistenceResult<List<SaleModels.PaymentMethod>> paymentMethods(SessionIdentity identity) {
        if(!uot.hasPermission(identity,"VENTAS_LISTAR"))return PersistenceResult.error("Seleccione un contexto con acceso a ventas.");
        try{return PersistenceResult.ok("Métodos de pago consultados correctamente.",jdbc.query("SELECT metodo_pago_id,codigo,nombre,requiere_numero_operacion FROM comercial.MetodoPago WHERE estado=1 ORDER BY nombre",(rs,n)->new SaleModels.PaymentMethod(rs.getInt(1),rs.getString(2),rs.getString(3),rs.getBoolean(4))));}
        catch(DataAccessException e){return PersistenceResult.error("No se pudieron consultar los métodos de pago.");}
    }

    @Override
    public PersistenceResult<Long> create(SessionIdentity identity, SaleCommands.Create c) {
        String details;
        try{details=json.writeValueAsString(c.lines().stream().map(x->map("productoId",x.productId(),"cantidad",x.quantity())).toList());}
        catch(RuntimeException e){return PersistenceResult.error("El detalle de la venta no es válido.");}
        Map<String,Object> out=procedures.call("comercial","PA_Venta_Ins_Registrar",map(
                        "nUsuarioId",identity.usuarioId(),"nUotId",c.uotId(),"nAlmacenId",c.warehouseId(),"nClientePersonaId",c.customerPersonId(),"nClienteEmpresaId",c.customerCompanyId(),
                        "gClaveIdempotencia",c.idempotencyKey().toString(),"cDetalleJson",details,"bSeparar",c.reservation(),"dReservaHasta",c.reservationUntil(),"cObservacion",c.observation()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nUotId",Types.BIGINT),new SqlParameter("nAlmacenId",Types.BIGINT),new SqlParameter("nClientePersonaId",Types.BIGINT),new SqlParameter("nClienteEmpresaId",Types.BIGINT),
                new SqlParameter("gClaveIdempotencia",Types.VARCHAR),new SqlParameter("cDetalleJson",Types.NVARCHAR),new SqlParameter("bSeparar",Types.BIT),new SqlParameter("dReservaHasta",Types.TIMESTAMP),new SqlParameter("cObservacion",Types.NVARCHAR),
                new SqlOutParameter("nVentaId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return idResult(out,"nVentaId","No se pudo registrar la venta.");
    }

    @Override
    public PersistenceResult<Long> pay(SessionIdentity identity, SaleCommands.Pay c) {
        Map<String,Object> out=procedures.call("comercial","PA_Venta_Ins_Pago",map("nUsuarioId",identity.usuarioId(),"nVentaId",c.saleId(),"nMetodoPagoId",c.paymentMethodId(),"nImporte",c.amount(),"gClaveIdempotencia",c.idempotencyKey().toString(),"cNumeroOperacion",c.operationNumber()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nVentaId",Types.BIGINT),new SqlParameter("nMetodoPagoId",Types.SMALLINT),new SqlParameter("nImporte",Types.DECIMAL),new SqlParameter("gClaveIdempotencia",Types.VARCHAR),new SqlParameter("cNumeroOperacion",Types.VARCHAR),new SqlOutParameter("nPagoVentaId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return idResult(out,"nPagoVentaId","No se pudo registrar el pago.");
    }

    @Override
    public PersistenceResult<Void> deliver(SessionIdentity identity, SaleCommands.Deliver c) {
        Map<String,Object> out=procedures.call("comercial","PA_Venta_Upd_Entregar",map("nUsuarioId",identity.usuarioId(),"nVentaId",c.saleId(),"gClaveIdempotencia",c.idempotencyKey().toString()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nVentaId",Types.BIGINT),new SqlParameter("gClaveIdempotencia",Types.VARCHAR),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return voidResult(out,"No se pudo entregar la venta.");
    }

    @Override
    public PersistenceResult<Void> cancel(SessionIdentity identity, SaleCommands.Cancel c) {
        try {
            String current=jdbc.queryForObject("SELECT estado_venta FROM comercial.Venta WHERE venta_id=?",String.class,c.saleId());
            if("ANULADA".equalsIgnoreCase(current))return PersistenceResult.ok("La venta ya se encuentra anulada.",null);
        } catch (DataAccessException ignored) { }
        Map<String,Object> out=procedures.call("comercial","PA_Venta_Upd_Anular",map("nUsuarioId",identity.usuarioId(),"nVentaId",c.saleId(),"cMotivo",c.reason()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nVentaId",Types.BIGINT),new SqlParameter("cMotivo",Types.NVARCHAR),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return voidResult(out,"No se pudo anular la venta.");
    }

    @Override
    public PersistenceResult<Void> cancelPayment(SessionIdentity identity, SaleCommands.CancelPayment c) {
        try {
            Boolean active=jdbc.queryForObject("SELECT estado FROM comercial.PagoVenta WHERE pago_venta_id=?",Boolean.class,c.paymentId());
            if(Boolean.FALSE.equals(active))return PersistenceResult.ok("El pago ya se encuentra anulado.",null);
        } catch (DataAccessException ignored) { }
        Map<String,Object> out=procedures.call("comercial","PA_PagoVenta_Upd_Anular",map("nUsuarioId",identity.usuarioId(),"nPagoVentaId",c.paymentId(),"cMotivo",c.reason()),
                new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nPagoVentaId",Types.BIGINT),new SqlParameter("cMotivo",Types.NVARCHAR),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        return voidResult(out,"No se pudo anular el pago.");
    }

    @Override
    public PersistenceResult<Long> issueReceipt(SessionIdentity identity, SaleCommands.IssueReceipt c) {
        return idempotency.executeLong(identity.usuarioId(), c.idempotencyKey(), "VENTA_COMPROBANTE", "comercial", c.type(), () -> {
            Map<String,Object> out=procedures.call("comercial","PA_Venta_Ins_Comprobante",map("nUsuarioId",identity.usuarioId(),"nVentaId",c.saleId(),"cTipo",c.type(),"cSerie",c.series(),"nNumero",c.number(),"cDocumentoCliente",c.customerDocument(),"cNombreCliente",c.customerName()),
                    new SqlParameter("nUsuarioId",Types.BIGINT),new SqlParameter("nVentaId",Types.BIGINT),new SqlParameter("cTipo",Types.VARCHAR),new SqlParameter("cSerie",Types.VARCHAR),new SqlParameter("nNumero",Types.BIGINT),new SqlParameter("cDocumentoCliente",Types.VARCHAR),new SqlParameter("cNombreCliente",Types.NVARCHAR),new SqlOutParameter("nComprobanteId",Types.BIGINT),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
            return idResult(out,"nComprobanteId","No se pudo emitir el comprobante.");
        });
    }

    @Override
    public PersistenceResult<Integer> expireReservations() {
        Map<String,Object> out=procedures.call("comercial","PA_Venta_Upd_VencerReservas",map("dAhora",null),new SqlParameter("dAhora",Types.TIMESTAMP),new SqlOutParameter("nProcesadas",Types.INTEGER),new SqlOutParameter("bResultado",Types.BIT),new SqlOutParameter("cMensaje",Types.NVARCHAR));
        if(!SqlProcedureExecutor.success(out))return PersistenceResult.error(SqlProcedureExecutor.message(out,"No se pudieron procesar las reservas vencidas."));
        return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Reservas procesadas correctamente."),SqlProcedureExecutor.intValue(out,"nProcesadas"));
    }

    private Long scope(SessionIdentity identity,Long requested,String permission){
        if(requested!=null)return uot.hasPermission(identity,requested,permission)?requested:INVALID_SCOPE;
        var result=uot.context(identity);if(!result.exitoso()||result.datos()==null)return INVALID_SCOPE;
        if("GENERAL".equals(result.datos().mode()))return null;
        Long selected=result.datos().selectedUotId();return selected!=null&&uot.hasPermission(identity,selected,permission)?selected:INVALID_SCOPE;
    }

    private SaleModels.Receipt receipt(Long saleId){
        List<SaleModels.Receipt> b=jdbc.query("SELECT boleta_id,serie,numero,fecha_emision FROM comercial.Boleta WHERE venta_id=? AND estado=1",(rs,n)->new SaleModels.Receipt("BOLETA",rs.getLong(1),rs.getString(2),rs.getLong(3),dateTime(rs,4)),saleId);
        if(!b.isEmpty())return b.getFirst();
        List<SaleModels.Receipt> f=jdbc.query("SELECT factura_id,serie,numero,fecha_emision FROM comercial.Factura WHERE venta_id=? AND estado=1",(rs,n)->new SaleModels.Receipt("FACTURA",rs.getLong(1),rs.getString(2),rs.getLong(3),dateTime(rs,4)),saleId);
        return f.isEmpty()?null:f.getFirst();
    }
    private static SaleModels.Summary summary(java.sql.ResultSet rs)throws java.sql.SQLException{return new SaleModels.Summary(rs.getLong("venta_id"),rs.getLong("uot_id"),rs.getString("uot_nombre"),rs.getLong("almacen_id"),rs.getString("almacen"),dateTime(rs, "fecha_hora"),dateTime(rs,"fecha_reserva_hasta"),rs.getString("estado_venta"),rs.getString("moneda"),rs.getBigDecimal("total"),rs.getBigDecimal("pagado"),rs.getBigDecimal("saldo"),rs.getString("cliente"),rs.getLong("vendedor_usuario_id"));}
    private static LocalDateTime dateTime(java.sql.ResultSet rs,int index)throws java.sql.SQLException{java.sql.Timestamp v=rs.getTimestamp(index);return v==null?null:v.toLocalDateTime();}
    private static LocalDateTime dateTime(java.sql.ResultSet rs,String name)throws java.sql.SQLException{java.sql.Timestamp v=rs.getTimestamp(name);return v==null?null:v.toLocalDateTime();}
    private static PersistenceResult<Long> idResult(Map<String,Object> out,String key,String fallback){if(!SqlProcedureExecutor.success(out))return PersistenceResult.error(SqlProcedureExecutor.message(out,fallback));return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Registro creado correctamente."),SqlProcedureExecutor.longValue(out,key));}
    private static PersistenceResult<Void> voidResult(Map<String,Object> out,String fallback){if(!SqlProcedureExecutor.success(out))return PersistenceResult.error(SqlProcedureExecutor.message(out,fallback));return PersistenceResult.ok(SqlProcedureExecutor.message(out,"Acción realizada."),null);}
    private static Map<String,Object> map(Object...pairs){Map<String,Object> values=new LinkedHashMap<>();for(int i=0;i<pairs.length;i+=2)values.put(String.valueOf(pairs[i]),pairs[i+1]);return values;}
}
