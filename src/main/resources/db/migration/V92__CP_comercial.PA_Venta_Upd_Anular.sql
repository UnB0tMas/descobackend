IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_Anular]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_Anular];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_Anular
' Descripción             : Anula una venta.
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
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo anular la venta.';
 DECLARE @UOT BIGINT,@Almacen BIGINT,@Estado VARCHAR(20); SELECT @UOT=uot_id,@Almacen=almacen_id,@Estado=estado_venta FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1;
 IF @UOT IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.'; RETURN; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UOT,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para anular ventas.'; RETURN; END;
 IF NULLIF(LTRIM(RTRIM(@cMotivo)),N'') IS NULL BEGIN SET @cMensaje=N'Indique el motivo de anulación.'; RETURN; END;
 IF @Estado='ENTREGADA' BEGIN SET @cMensaje=N'Una venta entregada requiere un proceso de devolución, no anulación directa.'; RETURN; END;
 IF EXISTS(SELECT 1 FROM comercial.PagoVenta WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO') BEGIN SET @cMensaje=N'Anule primero los pagos confirmados antes de anular la venta.'; RETURN; END;
 IF @Estado='ANULADA' BEGIN SET @bResultado=1; SET @cMensaje=N'La venta ya se encuentra anulada.'; RETURN; END;
 BEGIN TRY BEGIN TRAN;
 UPDATE S SET stock_reservado=S.stock_reservado-RS.cantidad,fecha_actualizacion=SYSUTCDATETIME()
 FROM logistica.AlmacenProductoStock S JOIN logistica.ReservaStock RS ON RS.almacen_id=S.almacen_id AND RS.producto_id=S.producto_id
 JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id WHERE DV.venta_id=@nVentaId AND RS.estado_reserva='ACTIVA' AND RS.estado=1;
 UPDATE RS SET estado_reserva='LIBERADA',fecha_liberacion=SYSUTCDATETIME() FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id WHERE DV.venta_id=@nVentaId AND RS.estado_reserva='ACTIVA';
 UPDATE comercial.Venta SET estado_venta='ANULADA',fecha_anulacion=SYSUTCDATETIME(),usuario_anulacion_id=@nUsuarioId,motivo_anulacion=@cMotivo WHERE venta_id=@nVentaId;
 COMMIT; SET @bResultado=1; SET @cMensaje=N'Venta anulada correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudo anular la venta.'; END CATCH;
END;
GO
