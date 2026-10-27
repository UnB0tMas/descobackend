IF OBJECT_ID(N'[comercial].[PA_Venta_Upd_VencerReservas]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Upd_VencerReservas];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Upd_VencerReservas
' Descripción             : Procesa las reservas de venta vencidas.
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
        @nProcesadas INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Upd_VencerReservas]
        @dAhora = '2026-10-11',
        @nProcesadas = @nProcesadas OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nProcesadas, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE comercial.PA_Venta_Upd_VencerReservas
 @dAhora DATETIME2(0)=NULL,@nProcesadas INT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @dAhora=COALESCE(@dAhora,SYSUTCDATETIME()); SET @nProcesadas=0; SET @bResultado=0; SET @cMensaje=N'No se pudieron liberar las reservas vencidas.';
 BEGIN TRY BEGIN TRAN;
 ;WITH R AS(SELECT RS.reserva_stock_id,RS.almacen_id,RS.producto_id,RS.cantidad,DV.venta_id FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id JOIN comercial.Venta V ON V.venta_id=DV.venta_id WHERE RS.estado=1 AND RS.estado_reserva='ACTIVA' AND RS.fecha_expiracion IS NOT NULL AND RS.fecha_expiracion<=@dAhora AND V.estado_venta IN('SEPARADA','REGISTRADA'))
 UPDATE S SET stock_reservado=S.stock_reservado-R.cantidad,fecha_actualizacion=SYSUTCDATETIME() FROM logistica.AlmacenProductoStock S JOIN R ON R.almacen_id=S.almacen_id AND R.producto_id=S.producto_id;
 UPDATE RS SET estado_reserva='VENCIDA',fecha_liberacion=@dAhora FROM logistica.ReservaStock RS JOIN comercial.DetalleVenta DV ON DV.detalle_venta_id=RS.detalle_venta_id JOIN comercial.Venta V ON V.venta_id=DV.venta_id WHERE RS.estado=1 AND RS.estado_reserva='ACTIVA' AND RS.fecha_expiracion IS NOT NULL AND RS.fecha_expiracion<=@dAhora AND V.estado_venta IN('SEPARADA','REGISTRADA');
 SET @nProcesadas=@@ROWCOUNT;
 UPDATE V SET estado_venta='ANULADA',fecha_anulacion=@dAhora,motivo_anulacion=N'Reserva vencida automáticamente.' FROM comercial.Venta V WHERE V.estado_venta='SEPARADA' AND V.fecha_reserva_hasta<=@dAhora AND NOT EXISTS(SELECT 1 FROM comercial.PagoVenta P WHERE P.venta_id=V.venta_id AND P.estado=1 AND P.estado_pago='CONFIRMADO');
 COMMIT; SET @bResultado=1; SET @cMensaje=N'Reservas vencidas procesadas correctamente.';
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudieron liberar las reservas vencidas.'; END CATCH;
END;
GO
