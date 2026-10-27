IF OBJECT_ID(N'[comercial].[PA_Venta_Ins_Comprobante]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Ins_Comprobante];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Ins_Comprobante
' Descripción             : Registra un comprobante asociado a una venta.
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
        @nComprobanteId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Ins_Comprobante]
        @nUsuarioId = 0,
        @nVentaId = 0,
        @cTipo = '',
        @cSerie = '',
        @nNumero = 0,
        @cDocumentoCliente = '',
        @cNombreCliente = N'',
        @nComprobanteId = @nComprobanteId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nComprobanteId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Ins_Comprobante]
 @nUsuarioId BIGINT,@nVentaId BIGINT,@cTipo VARCHAR(10),@cSerie VARCHAR(10),@nNumero BIGINT,@cDocumentoCliente VARCHAR(30)=NULL,@cNombreCliente NVARCHAR(220)=NULL,
 @nComprobanteId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @nComprobanteId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo emitir el comprobante.';
 DECLARE @UOT BIGINT,@Subtotal DECIMAL(19,4),@Impuesto DECIMAL(19,4),@Total DECIMAL(19,4); SELECT @UOT=uot_id,@Subtotal=subtotal,@Impuesto=impuesto,@Total=total FROM comercial.Venta WHERE venta_id=@nVentaId AND estado=1 AND estado_venta<>'ANULADA';
 IF @UOT IS NULL BEGIN SET @cMensaje=N'La venta no está disponible.'; RETURN; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UOT,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para emitir comprobantes.'; RETURN; END;
 SET @cTipo=UPPER(NULLIF(LTRIM(RTRIM(@cTipo)),'')); SET @cSerie=UPPER(NULLIF(LTRIM(RTRIM(@cSerie)),''));
 IF @cTipo NOT IN('BOLETA','FACTURA') OR @cSerie IS NULL OR @nNumero<=0 BEGIN SET @cMensaje=N'Complete correctamente los datos del comprobante.'; RETURN; END;
 BEGIN TRY
  IF @cTipo='BOLETA'
  BEGIN
    INSERT comercial.Boleta(venta_id,serie,numero,cliente_documento,cliente_nombre,subtotal,impuesto,total,estado_comprobante,estado)
    VALUES(@nVentaId,@cSerie,@nNumero,@cDocumentoCliente,@cNombreCliente,@Subtotal,@Impuesto,@Total,'EMITIDO',1); SET @nComprobanteId=SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    IF LEN(ISNULL(@cDocumentoCliente,''))<>11 OR @cDocumentoCliente LIKE '%[^0-9]%' OR NULLIF(LTRIM(RTRIM(@cNombreCliente)),N'') IS NULL BEGIN SET @cMensaje=N'Para factura ingrese RUC y razón social válidos.'; RETURN; END;
    INSERT comercial.Factura(venta_id,serie,numero,cliente_ruc,cliente_razon_social,subtotal,impuesto,total,estado_comprobante,estado)
    VALUES(@nVentaId,@cSerie,@nNumero,@cDocumentoCliente,@cNombreCliente,@Subtotal,@Impuesto,@Total,'EMITIDO',1); SET @nComprobanteId=SCOPE_IDENTITY();
  END;
  SET @bResultado=1; SET @cMensaje=N'Comprobante emitido correctamente.';
 END TRY BEGIN CATCH SET @nComprobanteId=NULL; SET @cMensaje=N'No se pudo emitir el comprobante. Revise la serie, número y la venta.'; END CATCH;
END;
GO
