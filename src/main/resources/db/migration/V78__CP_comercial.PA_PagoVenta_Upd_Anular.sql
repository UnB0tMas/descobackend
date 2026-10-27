IF OBJECT_ID(N'[comercial].[PA_PagoVenta_Upd_Anular]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_PagoVenta_Upd_Anular];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_PagoVenta_Upd_Anular
' Descripción             : Anula un pago de venta.
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
    EXEC [comercial].[PA_PagoVenta_Upd_Anular]
        @nUsuarioId = 0,
        @nPagoVentaId = 0,
        @cMotivo = N'',
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_PagoVenta_Upd_Anular]
 @nUsuarioId BIGINT,@nPagoVentaId BIGINT,@cMotivo NVARCHAR(400),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo anular el pago.';
 DECLARE @Venta BIGINT,@UOT BIGINT,@EstadoVenta VARCHAR(20); SELECT @Venta=PV.venta_id,@UOT=V.uot_id,@EstadoVenta=V.estado_venta FROM comercial.PagoVenta PV JOIN comercial.Venta V ON V.venta_id=PV.venta_id WHERE PV.pago_venta_id=@nPagoVentaId AND PV.estado=1 AND PV.estado_pago='CONFIRMADO';
 IF @Venta IS NULL BEGIN SET @cMensaje=N'El pago no está disponible.'; RETURN; END;
 IF @EstadoVenta='ENTREGADA' BEGIN SET @cMensaje=N'No se puede anular un pago de una venta ya entregada.'; RETURN; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UOT,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para anular pagos.'; RETURN; END;
 IF NULLIF(LTRIM(RTRIM(@cMotivo)),N'') IS NULL BEGIN SET @cMensaje=N'Indique el motivo de anulación del pago.'; RETURN; END;
 BEGIN TRY BEGIN TRAN;
 UPDATE comercial.PagoVenta SET estado_pago='ANULADO',estado=0,fecha_anulacion=SYSUTCDATETIME(),usuario_anulacion_id=@nUsuarioId,motivo_anulacion=@cMotivo WHERE pago_venta_id=@nPagoVentaId;
 DECLARE @Total DECIMAL(19,4)=(SELECT total FROM comercial.Venta WHERE venta_id=@Venta),@Pagado DECIMAL(19,4)=ISNULL((SELECT SUM(importe) FROM comercial.PagoVenta WHERE venta_id=@Venta AND estado=1 AND estado_pago='CONFIRMADO'),0);
 UPDATE comercial.Venta SET estado_venta=CASE WHEN @Pagado=0 THEN CASE WHEN EXISTS(SELECT 1 FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id WHERE DV.venta_id=@Venta AND RS.estado_reserva='ACTIVA') THEN 'SEPARADA' ELSE 'REGISTRADA' END WHEN @Pagado<@Total THEN 'PAGO_PARCIAL' ELSE 'PAGADA' END WHERE venta_id=@Venta;
 COMMIT; SET @bResultado=1; SET @cMensaje=N'Pago anulado correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudo anular el pago.'; END CATCH;
END;
GO
