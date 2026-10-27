IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_VencerReservas]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_VencerReservas];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_VencerReservas
' Descripción             : Libera reservas POS vencidas sin duplicar descuentos.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de vencimiento y stock reservado.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nProcesadas INT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Upd_VencerReservas]
        @dAhora = '2026-10-11T00:00:00',
        @nProcesadas = @nProcesadas OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nProcesadas, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Upd_VencerReservas]
 @dAhora DATETIME2(0)=NULL,@nProcesadas INT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @dAhora=COALESCE(@dAhora,SYSUTCDATETIME()),@nProcesadas=0,@bResultado=0,
  @cMensaje=N'No se pudieron liberar las reservas vencidas.';
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  DECLARE @Vencidas TABLE(reserva_stock_id BIGINT PRIMARY KEY,almacen_id BIGINT,producto_id BIGINT,cantidad DECIMAL(19,3));
  INSERT @Vencidas(reserva_stock_id,almacen_id,producto_id,cantidad)
  SELECT RS.reserva_stock_id,RS.almacen_id,RS.producto_id,RS.cantidad
  FROM logistica.ReservaStock RS WITH(UPDLOCK,HOLDLOCK)
  JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
  JOIN comercial.Venta V ON V.venta_id=DV.venta_id
  WHERE RS.estado=1 AND RS.estado_reserva='ACTIVA' AND RS.fecha_expiracion<=@dAhora
   AND V.estado=1 AND V.estado_venta IN('SEPARADA','REGISTRADA');
  ;WITH D AS(SELECT almacen_id,producto_id,SUM(cantidad) cantidad FROM @Vencidas GROUP BY almacen_id,producto_id)
  UPDATE S SET stock_reservado=S.stock_reservado-D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
  FROM logistica.AlmacenProductoStock S JOIN D ON D.almacen_id=S.almacen_id AND D.producto_id=S.producto_id
  WHERE S.stock_reservado>=D.cantidad;
  IF @@ROWCOUNT<>(SELECT COUNT(*) FROM (SELECT almacen_id,producto_id FROM @Vencidas GROUP BY almacen_id,producto_id) C)
    THROW 51083,N'RESERVA',1;
  UPDATE RS SET estado_reserva='VENCIDA',fecha_liberacion=@dAhora
  FROM logistica.ReservaStock RS JOIN @Vencidas V ON V.reserva_stock_id=RS.reserva_stock_id;
  SET @nProcesadas=@@ROWCOUNT;
  UPDATE V SET estado_venta='ANULADA',fecha_anulacion=@dAhora,motivo_anulacion=N'Reserva vencida automáticamente.'
  FROM comercial.Venta V
  WHERE V.estado=1 AND V.estado_venta='SEPARADA' AND V.fecha_reserva_hasta<=@dAhora
   AND NOT EXISTS(SELECT 1 FROM comercial.PagoVenta P WHERE P.venta_id=V.venta_id AND P.estado=1 AND P.estado_pago='CONFIRMADO');
  COMMIT;SELECT @bResultado=1,@cMensaje=N'Reservas vencidas procesadas correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;SET @nProcesadas=0;
  SET @cMensaje=N'No se pudieron liberar las reservas vencidas. Verifique la consistencia del inventario.';
 END CATCH;
END;
GO
