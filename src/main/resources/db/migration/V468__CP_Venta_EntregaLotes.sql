IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Entregar]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_Entregar];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_Entregar
' Descripción             : Entrega una venta pagada y registra salida de Kardex y reservas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de entrega y consistencia de reservas.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Upd_Entregar]
        @nUsuarioId = 0,
        @nVentaId = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Entregar]', N'P') IS NOT NULL DROP PROCEDURE [comercial].[PA_Venta_Upd_Entregar];
GO
CREATE PROCEDURE [comercial].[PA_Venta_Upd_Entregar]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@gClaveIdempotencia UNIQUEIDENTIFIER,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo entregar la venta.';
 IF @gClaveIdempotencia IS NULL BEGIN SET @cMensaje=N'La solicitud no contiene una clave válida.';RETURN;END;
 DECLARE @Uot BIGINT,@Almacen BIGINT,@Total DECIMAL(19,4),@Estado VARCHAR(20),@Reservas INT,@Detalles INT;
 SELECT @Uot=uot_id FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1;
 IF @Uot IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para entregar ventas.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @Uot=uot_id,@Almacen=almacen_id,@Total=total,@Estado=estado_venta
  FROM comercial.Venta WITH(UPDLOCK,HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1;
  IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'POS_OPERAR')=0 THROW 51081,N'PERMISO',1;
  IF @Estado='ENTREGADA'
  BEGIN COMMIT;SELECT @bResultado=1,@cMensaje=N'La venta ya fue entregada.';RETURN;END;
  IF @Estado<>'PAGADA' THROW 51081,N'ESTADO',1;
  IF NOT EXISTS(SELECT 1 FROM logistica.Almacen A JOIN logistica.AlmacenUOT AU ON AU.almacen_id=A.almacen_id
    AND AU.uot_id=@Uot AND AU.estado=1 AND AU.fecha_hasta IS NULL AND AU.permite_salida=1
    WHERE A.almacen_id=@Almacen AND A.uot_propietaria_id=@Uot AND A.estado=1) THROW 51081,N'ALMACEN',1;
  IF ISNULL((SELECT SUM(importe) FROM comercial.PagoVenta WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO'),0)<>@Total
    THROW 51081,N'PAGO',1;
  SELECT @Detalles=COUNT(*) FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1;
  SELECT @Reservas=COUNT(*) FROM logistica.ReservaStock RS WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
   WHERE DV.venta_id=@nVentaId AND DV.estado=1 AND RS.estado=1 AND RS.estado_reserva='ACTIVA';
  IF @Detalles=0 OR (@Reservas<>0 AND @Reservas<>@Detalles) THROW 51081,N'RESERVA',1;
  IF @Reservas>0
  BEGIN
    ;WITH D AS(SELECT RS.producto_id,SUM(RS.cantidad) cantidad
      FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
      WHERE DV.venta_id=@nVentaId AND DV.estado=1 AND RS.estado=1 AND RS.estado_reserva='ACTIVA'
      GROUP BY RS.producto_id)
    UPDATE S SET stock_actual=S.stock_actual-D.cantidad,stock_reservado=S.stock_reservado-D.cantidad,
      fecha_actualizacion=SYSUTCDATETIME()
    FROM logistica.AlmacenProductoStock S JOIN D ON D.producto_id=S.producto_id
    WHERE S.almacen_id=@Almacen AND S.stock_actual>=D.cantidad AND S.stock_reservado>=D.cantidad;
    IF @@ROWCOUNT<>(SELECT COUNT(DISTINCT producto_id) FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1)
      THROW 51081,N'STOCK',1;
    UPDATE RS SET estado_reserva='CONSUMIDA',fecha_liberacion=SYSUTCDATETIME()
    FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
    WHERE DV.venta_id=@nVentaId AND DV.estado=1 AND RS.estado=1 AND RS.estado_reserva='ACTIVA';
  END
  ELSE
  BEGIN
    ;WITH D AS(SELECT producto_id,SUM(cantidad) cantidad FROM comercial.DetalleVenta
     WHERE venta_id=@nVentaId AND estado=1 GROUP BY producto_id)
    UPDATE S SET stock_actual=S.stock_actual-D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
    FROM logistica.AlmacenProductoStock S JOIN D ON D.producto_id=S.producto_id
    WHERE S.almacen_id=@Almacen AND S.stock_disponible>=D.cantidad;
    IF @@ROWCOUNT<>(SELECT COUNT(DISTINCT producto_id) FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1)
      THROW 51081,N'STOCK',1;
  END;
  INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,documento_referencia,clave_idempotencia,usuario_id,observacion,estado)
  VALUES(@Almacen,@Uot,'VENTA','S',CONCAT('VENTA-',@nVentaId),@gClaveIdempotencia,@nUsuarioId,N'Salida generada por entrega de venta.',1);
  DECLARE @Mov BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda)
  SELECT @Mov,DV.producto_id,DV.cantidad,NULL,PP.moneda
  FROM comercial.DetalleVenta DV JOIN logistica.ProductoPrecio PP ON PP.producto_precio_id=DV.producto_precio_id
  WHERE DV.venta_id=@nVentaId AND DV.estado=1;
  UPDATE comercial.Venta SET estado_venta='ENTREGADA' WHERE venta_id=@nVentaId;
  COMMIT;SELECT @bResultado=1,@cMensaje=N'Venta entregada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=CASE WHEN ERROR_NUMBER()=51120 THEN ERROR_MESSAGE() WHEN ERROR_MESSAGE() LIKE '%STOCK%' THEN N'No hay existencias suficientes para entregar la venta.'
   WHEN ERROR_MESSAGE() LIKE '%RESERVA%' THEN N'La reserva de la venta requiere revisión antes de entregarla.'
   WHEN ERROR_MESSAGE() LIKE '%PAGO%' THEN N'El importe confirmado no coincide con el total de la venta.'
   WHEN ERROR_MESSAGE() LIKE '%ESTADO%' THEN N'La venta debe estar pagada antes de entregarse.'
   WHEN ERROR_MESSAGE() LIKE '%ALMACEN%' THEN N'El almacén de la venta no está habilitado para esta UOT.'
   WHEN ERROR_MESSAGE() LIKE '%PERMISO%' THEN N'No tiene permiso para entregar ventas de esta UOT.'
   ELSE N'No se pudo entregar la venta.' END;
 END CATCH;
END;
GO
