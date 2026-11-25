IF OBJECT_ID(N'[comercial].[PA_Venta_Ins_Pago]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Ins_Pago];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_Venta_Ins_Pago
' Descripción            : Registra venta para pago.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE [comercial].[PA_Venta_Ins_Pago]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@nMetodoPagoId SMALLINT,@nImporte DECIMAL(19,4),@gClaveIdempotencia UNIQUEIDENTIFIER,@cNumeroOperacion VARCHAR(120)=NULL,@nArchivoId BIGINT=NULL,
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

 -- El código es informativo y opcional para todos los medios de pago.
 IF @nArchivoId IS NOT NULL AND NOT EXISTS(
  SELECT 1 FROM archivo.Archivo A WHERE A.archivo_id=@nArchivoId AND A.uot_id=@UOT
    AND A.usuario_id=@nUsuarioId AND A.estado=1 AND A.proveedor_almacenamiento='LOCAL'
    AND A.mime_type IN('image/jpeg','image/png','image/webp')
    AND A.tamano_bytes BETWEEN 1 AND 8388608
    AND NOT EXISTS(SELECT 1 FROM comercial.PagoVenta PV WHERE PV.archivo_id=A.archivo_id)
 ) BEGIN SET @cMensaje=N'La evidencia del pago no es válida o ya está vinculada.'; RETURN; END;
 BEGIN TRY SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
 -- Bloquear primero la venta: impide registrar un pago mientras otra transacción la anula.
 IF NOT EXISTS(SELECT 1 FROM comercial.Venta WITH(UPDLOCK,HOLDLOCK)
   WHERE venta_id=@nVentaId AND estado=1 AND estado_venta NOT IN('ANULADA','ENTREGADA'))
   THROW 51071,N'VENTA_ESTADO_NO_PAGABLE',1;
 DECLARE @Pagado DECIMAL(19,4)=ISNULL((SELECT SUM(importe) FROM comercial.PagoVenta WITH(UPDLOCK,HOLDLOCK) WHERE venta_id=@nVentaId AND estado=1 AND estado_pago='CONFIRMADO'),0);
 IF @Pagado+@nImporte>@Total THROW 51070,N'PAGO_SUPERA_TOTAL',1;
 INSERT comercial.PagoVenta(venta_id,metodo_pago_id,importe,moneda,numero_operacion,usuario_id,estado_pago,estado,clave_idempotencia,archivo_id)
 VALUES(@nVentaId,@nMetodoPagoId,@nImporte,(SELECT moneda FROM comercial.Venta WHERE venta_id=@nVentaId),
    NULLIF(LTRIM(RTRIM(@cNumeroOperacion)),''),@nUsuarioId,'CONFIRMADO',1,@gClaveIdempotencia,@nArchivoId);
 SET @nPagoVentaId=SCOPE_IDENTITY(); SET @Pagado=@Pagado+@nImporte;
 UPDATE comercial.Venta SET estado_venta=CASE WHEN @Pagado=@Total THEN 'PAGADA' ELSE 'PAGO_PARCIAL' END WHERE venta_id=@nVentaId AND estado_venta<>'ENTREGADA';
 COMMIT; SET @bResultado=1; SET @cMensaje=CASE WHEN @Pagado=@Total THEN N'Pago registrado. La venta quedó pagada.' ELSE N'Adelanto registrado correctamente.' END;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @nPagoVentaId=NULL; SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%PAGO_SUPERA_TOTAL%' THEN N'El pago supera el saldo pendiente de la venta.' WHEN ERROR_MESSAGE() LIKE '%VENTA_ESTADO_NO_PAGABLE%' THEN N'La venta fue anulada o ya fue entregada.' ELSE N'No se pudo registrar el pago.' END; END CATCH;
END;
GO
