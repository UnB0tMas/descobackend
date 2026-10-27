IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Anular]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_Anular];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_Anular
' Descripción             : Anula una venta y libera sus reservas de stock.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de anulación transaccional y UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Upd_Anular]
        @nUsuarioId = 0,
        @nVentaId = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Upd_Anular]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@cMotivo NVARCHAR(500),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo anular la venta.';
 DECLARE @Uot BIGINT,@Almacen BIGINT,@Estado VARCHAR(20);
 SELECT @Uot=uot_id FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1;
 IF @Uot IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para anular ventas.';RETURN;END;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
 IF @cMotivo IS NULL BEGIN SET @cMensaje=N'Indique el motivo de anulación.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @Uot=uot_id,@Almacen=almacen_id,@Estado=estado_venta
  FROM comercial.Venta WITH(UPDLOCK,HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1;
  IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,'POS_OPERAR')=0 THROW 51082,N'PERMISO',1;
  IF @Estado='ANULADA' BEGIN COMMIT;SELECT @bResultado=1,@cMensaje=N'La venta ya se encuentra anulada.';RETURN;END;
  IF @Estado='ENTREGADA' THROW 51082,N'ENTREGADA',1;
  IF EXISTS(SELECT 1 FROM comercial.PagoVenta WITH(HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO') THROW 51082,N'PAGOS',1;
  ;WITH D AS(SELECT RS.almacen_id,RS.producto_id,SUM(RS.cantidad) cantidad
   FROM logistica.ReservaStock RS WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
   WHERE DV.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA'
   GROUP BY RS.almacen_id,RS.producto_id)
  UPDATE S SET stock_reservado=S.stock_reservado-D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
  FROM logistica.AlmacenProductoStock S JOIN D ON D.almacen_id=S.almacen_id AND D.producto_id=S.producto_id
  WHERE S.stock_reservado>=D.cantidad;
  IF @@ROWCOUNT<>(SELECT COUNT(*) FROM (SELECT RS.almacen_id,RS.producto_id
   FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
   WHERE DV.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA' GROUP BY RS.almacen_id,RS.producto_id) C)
    THROW 51082,N'RESERVA',1;
  UPDATE RS SET estado_reserva='LIBERADA',fecha_liberacion=SYSUTCDATETIME()
  FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id
  WHERE DV.venta_id=@nVentaId AND RS.estado=1 AND RS.estado_reserva='ACTIVA';
  UPDATE comercial.Venta SET estado_venta='ANULADA',fecha_anulacion=SYSUTCDATETIME(),
   usuario_anulacion_id=@nUsuarioId,motivo_anulacion=@cMotivo WHERE venta_id=@nVentaId;
  COMMIT;SELECT @bResultado=1,@cMensaje=N'Venta anulada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%ENTREGADA%' THEN N'La venta entregada requiere un proceso de devolución.'
    WHEN ERROR_MESSAGE() LIKE '%PAGOS%' THEN N'Anule primero los pagos confirmados.'
    WHEN ERROR_MESSAGE() LIKE '%PERMISO%' THEN N'No tiene permiso para anular ventas de esta UOT.'
    WHEN ERROR_MESSAGE() LIKE '%RESERVA%' THEN N'La reserva de la venta requiere revisión antes de anularla.'
    ELSE N'No se pudo anular la venta.' END;
 END CATCH;
END;
GO
