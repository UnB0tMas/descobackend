IF OBJECT_ID(N'[comercial].[PA_Venta_Ins_Pago]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Ins_Pago];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Ins_Pago
' Descripción             : Registra un pago asociado a una venta.
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
        @nPagoVentaId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Ins_Pago]
        @nUsuarioId = 0,
        @nVentaId = 0,
        @nMetodoPagoId = 0,
        @nImporte = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cNumeroOperacion = '',
        @nPagoVentaId = @nPagoVentaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nPagoVentaId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Ins_Pago]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@nMetodoPagoId SMALLINT,@nImporte DECIMAL(19,4),@gClaveIdempotencia UNIQUEIDENTIFIER,@cNumeroOperacion VARCHAR(120)=NULL,
 @nPagoVentaId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @nPagoVentaId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar el pago.';
 DECLARE @UOT BIGINT,@Total DECIMAL(19,4); SELECT @UOT=uot_id,@Total=total FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1 AND estado_venta<>'ANULADA';
 IF @UOT IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.'; RETURN; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UOT,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para registrar pagos.'; RETURN; END;
 IF @nImporte<=0 BEGIN SET @cMensaje=N'El importe debe ser mayor que cero.'; RETURN; END;
 IF @gClaveIdempotencia IS NULL BEGIN SET @cMensaje=N'La clave de idempotencia del pago es obligatoria.'; RETURN; END;
 SELECT @nPagoVentaId=pago_venta_id FROM comercial.PagoVenta WHERE clave_idempotencia=@gClaveIdempotencia; IF @nPagoVentaId IS NOT NULL BEGIN SET @bResultado=1; SET @cMensaje=N'El pago ya fue registrado correctamente.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM comercial.MetodoPago WHERE metodo_pago_id=@nMetodoPagoId AND estado=1) BEGIN SET @cMensaje=N'El método de pago no está disponible.'; RETURN; END;
 IF EXISTS(SELECT 1 FROM comercial.MetodoPago WHERE metodo_pago_id=@nMetodoPagoId AND requiere_numero_operacion=1 AND NULLIF(LTRIM(RTRIM(@cNumeroOperacion)),'') IS NULL) BEGIN SET @cMensaje=N'Ingrese el número de operación del pago.'; RETURN; END;
 BEGIN TRY SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
 DECLARE @Pagado DECIMAL(19,4)=ISNULL((SELECT SUM(importe) FROM comercial.PagoVenta WITH(UPDLOCK,HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO'),0);
 IF @Pagado+@nImporte>@Total THROW 51070,N'PAGO_SUPERA_TOTAL',1;
 INSERT comercial.PagoVenta(venta_id,metodo_pago_id,importe,moneda,numero_operacion,usuario_id,estado_pago,estado,clave_idempotencia) VALUES(@nVentaId,@nMetodoPagoId,@nImporte,'PEN',NULLIF(LTRIM(RTRIM(@cNumeroOperacion)),''),@nUsuarioId,'CONFIRMADO',1,@gClaveIdempotencia);
 SET @nPagoVentaId=SCOPE_IDENTITY(); SET @Pagado=@Pagado+@nImporte;
 UPDATE comercial.Venta SET estado_venta=CASE WHEN @Pagado=@Total THEN 'PAGADA' ELSE 'PAGO_PARCIAL' END WHERE venta_id=@nVentaId AND estado_venta<>'ENTREGADA';
 COMMIT; SET @bResultado=1; SET @cMensaje=CASE WHEN @Pagado=@Total THEN N'Pago registrado. La venta quedó pagada.' ELSE N'Adelanto registrado correctamente.' END;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @nPagoVentaId=NULL; SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%PAGO_SUPERA_TOTAL%' THEN N'El pago supera el saldo pendiente de la venta.' ELSE N'No se pudo registrar el pago.' END; END CATCH;
END;
GO
