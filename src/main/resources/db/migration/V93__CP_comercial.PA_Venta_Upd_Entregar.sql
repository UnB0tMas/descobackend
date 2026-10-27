IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Entregar]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_Entregar];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_Entregar
' Descripción             : Marca o procesa la entrega de una venta.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo de referencia: reemplazar valores e identificadores por datos válidos.
    DECLARE
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Upd_Entregar]
        @nUsuarioId = 0,
        @nVentaId = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Upd_Entregar]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@gClaveIdempotencia UNIQUEIDENTIFIER,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo entregar la venta.';
 DECLARE @UOT BIGINT,@Almacen BIGINT,@Total DECIMAL(19,4),@Estado VARCHAR(20); SELECT @UOT=uot_id,@Almacen=almacen_id,@Total=total,@Estado=estado_venta FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1;
 IF @UOT IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.'; RETURN; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UOT,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para entregar ventas.'; RETURN; END;
 IF @Estado='ENTREGADA' BEGIN SET @bResultado=1; SET @cMensaje=N'La venta ya fue entregada.'; RETURN; END;
 IF @Estado<>'PAGADA' BEGIN SET @cMensaje=N'La venta debe estar totalmente pagada antes de la entrega.'; RETURN; END;
 IF ISNULL((SELECT SUM(importe) FROM comercial.PagoVenta WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO'),0)<>@Total BEGIN SET @cMensaje=N'El total pagado no coincide con el total de la venta.'; RETURN; END;
 BEGIN TRY SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
 /* Reservas activas consumen stock reservado; ventas directas descuentan disponible. */
 IF EXISTS(SELECT 1 FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id WHERE DV.venta_id=@nVentaId AND RS.estado_reserva='ACTIVA' AND RS.estado=1)
 BEGIN
   UPDATE S SET stock_actual=S.stock_actual-DV.cantidad,stock_reservado=S.stock_reservado-DV.cantidad,fecha_actualizacion=SYSUTCDATETIME()
   FROM logistica.AlmacenProductoStock S JOIN comercial.DetalleVenta DV ON DV.producto_id=S.producto_id AND DV.venta_id=@nVentaId AND DV.estado=1 WHERE S.almacen_id=@Almacen;
   UPDATE RS SET estado_reserva='CONSUMIDA',fecha_liberacion=SYSUTCDATETIME()
   FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id WHERE DV.venta_id=@nVentaId AND RS.estado_reserva='ACTIVA';
 END
 ELSE
 BEGIN
   IF EXISTS(SELECT 1 FROM comercial.DetalleVenta DV LEFT JOIN logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK) ON S.almacen_id=@Almacen AND S.producto_id=DV.producto_id WHERE DV.venta_id=@nVentaId AND DV.estado=1 AND ISNULL(S.stock_disponible,0)<DV.cantidad) THROW 51080,N'ENTREGA_STOCK_INSUFICIENTE',1;
   UPDATE S SET stock_actual=S.stock_actual-DV.cantidad,fecha_actualizacion=SYSUTCDATETIME()
   FROM logistica.AlmacenProductoStock S JOIN comercial.DetalleVenta DV ON DV.producto_id=S.producto_id AND DV.venta_id=@nVentaId AND DV.estado=1 WHERE S.almacen_id=@Almacen;
 END;
 INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,documento_referencia,clave_idempotencia,usuario_id,observacion,estado)
 VALUES(@Almacen,@UOT,'VENTA','S',CONCAT('VENTA-',@nVentaId),@gClaveIdempotencia,@nUsuarioId,N'Salida generada por entrega de venta.',1);
 DECLARE @Mov BIGINT=SCOPE_IDENTITY();
 INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda)
 SELECT @Mov,producto_id,cantidad,NULL,'PEN' FROM comercial.DetalleVenta WHERE venta_id=@nVentaId AND estado=1;
 UPDATE comercial.Venta SET estado_venta='ENTREGADA' WHERE venta_id=@nVentaId;
 COMMIT; SET @bResultado=1; SET @cMensaje=N'Venta entregada correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%ENTREGA_STOCK_INSUFICIENTE%' THEN N'No hay stock suficiente para entregar la venta.' WHEN ERROR_NUMBER() IN(2601,2627) THEN N'La entrega ya fue procesada.' ELSE N'No se pudo entregar la venta.' END; END CATCH;
END;
GO
