IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Anular]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_Anular];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_Venta_Upd_Anular
' Descripción            : Gestiona venta: anular.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_Venta_Upd_Anular
 @nUsuarioId BIGINT,@nVentaId BIGINT,@cMotivo NVARCHAR(500),
 @bDevolucionConfirmada BIT=0,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No fue posible anular la venta.';
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
 IF @cMotivo IS NULL OR LEN(@cMotivo)<5 OR LEN(@cMotivo)>500
 BEGIN SET @cMensaje=N'Indique un motivo de al menos cinco caracteres.'; RETURN; END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  BEGIN TRAN;
  DECLARE @Uot BIGINT,@Almacen BIGINT,@Estado VARCHAR(20),@Moneda CHAR(3),
          @Pagado DECIMAL(19,4),@Movimiento BIGINT=NULL;
  SELECT @Uot=uot_id,@Almacen=almacen_id,@Estado=estado_venta,@Moneda=moneda
  FROM comercial.Venta WITH(UPDLOCK,HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1;
  IF @Uot IS NULL THROW 51110,N'VENTA_NO_DISPONIBLE',1;
  IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'VENTAS_ANULAR')<>1
   THROW 51111,N'VENTA_SIN_PERMISO',1;
  IF @Estado='ANULADA'
  BEGIN COMMIT;SELECT @bResultado=1,@cMensaje=N'La venta ya estaba anulada.'; RETURN; END;
  -- Una boleta/factura formal requiere una nota de crédito en el módulo fiscal; no simularla.
  IF EXISTS(SELECT 1 FROM comercial.Boleta WHERE venta_id=@nVentaId AND estado=1)
    OR EXISTS(SELECT 1 FROM comercial.Factura WHERE venta_id=@nVentaId AND estado=1)
   THROW 51112,N'VENTA_COMPROBANTE_FISCAL',1;
  SELECT @Pagado=COALESCE(SUM(importe),0) FROM comercial.PagoVenta WITH(UPDLOCK,HOLDLOCK)
  WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO';
  IF @Pagado>0 AND ISNULL(@bDevolucionConfirmada,0)<>1
   THROW 51113,N'VENTA_REEMBOLSO_PENDIENTE',1;
  IF @Estado='ENTREGADA'
  BEGIN
   ;WITH Cantidades AS (
     SELECT producto_id,SUM(cantidad) cantidad
     FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1 GROUP BY producto_id
   )
   UPDATE S SET stock_actual=S.stock_actual+C.cantidad,fecha_actualizacion=SYSUTCDATETIME()
   FROM logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK)
   JOIN Cantidades C ON C.producto_id=S.producto_id WHERE S.almacen_id=@Almacen;
   IF @@ROWCOUNT<>(SELECT COUNT(DISTINCT producto_id) FROM comercial.DetalleVenta
                   WHERE venta_id=@nVentaId AND estado=1)
    THROW 51114,N'VENTA_STOCK_REVERSA',1;
   DECLARE @Original BIGINT=(SELECT TOP(1) M.movimiento_inventario_id
     FROM logistica.MovimientoInventario M WHERE M.almacen_id=@Almacen
       AND M.documento_referencia=CONCAT('VENTA-',@nVentaId)
       AND M.tipo_movimiento='VENTA' AND M.estado=1
     ORDER BY M.movimiento_inventario_id DESC);
   IF @Original IS NULL THROW 51114,N'VENTA_STOCK_REVERSA',1;
   INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,
     movimiento_relacionado_id,documento_referencia,clave_idempotencia,usuario_id,observacion,estado)
   VALUES(@Almacen,@Uot,'DEVOLUCION','E',@Original,CONCAT('ANULACION-VENTA-',@nVentaId),
     NEWID(),@nUsuarioId,N'Reversa por anulación de venta; ver VentaAnulacionPOS.',1);
   SET @Movimiento=SCOPE_IDENTITY();
   INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda)
   SELECT @Movimiento,producto_id,SUM(cantidad),NULL,@Moneda
   FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1 GROUP BY producto_id;
  END
  ELSE
  BEGIN
   ;WITH Reservas AS(
     SELECT RS.almacen_id,RS.producto_id,SUM(RS.cantidad) cantidad
     FROM logistica.ReservaStock RS WITH(UPDLOCK,HOLDLOCK)
     JOIN comercial.DetalleVenta D ON D.detalle_venta_id=RS.detalle_venta_id
     WHERE D.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA'
     GROUP BY RS.almacen_id,RS.producto_id
   )
   UPDATE S SET stock_reservado=S.stock_reservado-R.cantidad,
      fecha_actualizacion=SYSUTCDATETIME()
   FROM logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK)
   JOIN Reservas R ON R.almacen_id=S.almacen_id AND R.producto_id=S.producto_id
   WHERE S.stock_reservado>=R.cantidad;
   IF @@ROWCOUNT<>(SELECT COUNT(*) FROM (
      SELECT RS.almacen_id,RS.producto_id FROM logistica.ReservaStock RS
      JOIN comercial.DetalleVenta D ON D.detalle_venta_id=RS.detalle_venta_id
      WHERE D.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA'
      GROUP BY RS.almacen_id,RS.producto_id) Q)
    THROW 51114,N'VENTA_STOCK_REVERSA',1;
   UPDATE RS SET estado_reserva='LIBERADA',fecha_liberacion=SYSUTCDATETIME()
   FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta D
     ON D.detalle_venta_id=RS.detalle_venta_id
   WHERE D.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA';
  END;
  UPDATE comercial.PagoVenta SET estado=0,estado_pago='ANULADO',
    fecha_anulacion=SYSUTCDATETIME(),usuario_anulacion_id=@nUsuarioId,motivo_anulacion=@cMotivo
  WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO';
  UPDATE comercial.Venta SET estado_venta='ANULADA',fecha_anulacion=SYSUTCDATETIME(),
    usuario_anulacion_id=@nUsuarioId,motivo_anulacion=@cMotivo WHERE venta_id=@nVentaId;
  INSERT comercial.VentaAnulacionPOS(venta_id,usuario_id,motivo,importe_reintegrado,
    devolucion_confirmada,movimiento_reversa_id)
  VALUES(@nVentaId,@nUsuarioId,@cMotivo,@Pagado,ISNULL(@bDevolucionConfirmada,0),@Movimiento);
  COMMIT;
  SELECT @bResultado=1,@cMensaje=N'Venta anulada con trazabilidad y reversa de inventario.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=CASE
   WHEN ERROR_MESSAGE() LIKE '%VENTA_REEMBOLSO_PENDIENTE%' THEN N'Confirme la devolución íntegra de los cobros al cliente antes de anular.'
   WHEN ERROR_MESSAGE() LIKE '%VENTA_COMPROBANTE_FISCAL%' THEN N'Existe un comprobante fiscal; gestione la nota de crédito antes de anular.'
   WHEN ERROR_MESSAGE() LIKE '%VENTA_STOCK_REVERSA%' THEN N'No se pudo revertir el stock. Revise el Kardex.'
   WHEN ERROR_MESSAGE() LIKE '%VENTA_SIN_PERMISO%' THEN N'Sin permiso para anular en esta UOT.'
   ELSE N'No fue posible anular la venta.' END;
 END CATCH;
END;
GO
