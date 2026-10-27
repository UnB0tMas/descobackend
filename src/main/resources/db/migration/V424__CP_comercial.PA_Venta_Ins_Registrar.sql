IF OBJECT_ID(N'[comercial].[PA_Venta_Ins_Registrar]', N'P') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_Venta_Ins_Registrar];
GO

/******************************************************************************************************
' Nombre del PA           : comercial.PA_Venta_Ins_Registrar
' Descripción             : Registra ventas POS con políticas de producto, UOT y reservas.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Comercial
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de controles de venta y stock UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nVentaId BIGINT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [comercial].[PA_Venta_Ins_Registrar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nAlmacenId = 0,
        @nClientePersonaId = 0,
        @nClienteEmpresaId = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cDetalleJson = N'[]',
        @bSeparar = 0,
        @dReservaHasta = '2026-10-11T00:00:00',
        @cObservacion = N'',
        @nVentaId = @nVentaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nVentaId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE [comercial].[PA_Venta_Ins_Registrar]
 @nUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@nClientePersonaId BIGINT=NULL,@nClienteEmpresaId BIGINT=NULL,
 @gClaveIdempotencia UNIQUEIDENTIFIER,@cDetalleJson NVARCHAR(MAX),@bSeparar BIT=0,@dReservaHasta DATETIME2(0)=NULL,@cObservacion NVARCHAR(500)=NULL,
 @nVentaId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @nVentaId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar la venta.';
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'POS_OPERAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para registrar ventas.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenId AND uot_propietaria_id=@nUotId AND estado=1) BEGIN SET @cMensaje=N'El almacén no pertenece a la UOT seleccionada.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1) BEGIN SET @cMensaje=N'La UOT no puede vender desde el almacén seleccionado.'; RETURN; END;
 IF @nClientePersonaId IS NOT NULL AND @nClienteEmpresaId IS NOT NULL BEGIN SET @cMensaje=N'Seleccione un solo cliente para la venta.'; RETURN; END;
 IF @nClientePersonaId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Persona WHERE persona_id=@nClientePersonaId AND estado=1) BEGIN SET @cMensaje=N'El cliente seleccionado no está disponible.'; RETURN; END;
 IF @nClienteEmpresaId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM org.Empresa WHERE empresa_id=@nClienteEmpresaId AND estado=1) BEGIN SET @cMensaje=N'El cliente seleccionado no está disponible.'; RETURN; END;
 IF @bSeparar=1 AND (@dReservaHasta IS NULL OR @dReservaHasta<=SYSUTCDATETIME()) BEGIN SET @cMensaje=N'La fecha límite de la separación debe ser futura.'; RETURN; END;
 IF @gClaveIdempotencia IS NULL OR ISJSON(@cDetalleJson)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson)) BEGIN SET @cMensaje=N'La venta debe incluir productos válidos.'; RETURN; END;
 SELECT @nVentaId=venta_id FROM comercial.Venta WHERE clave_idempotencia=@gClaveIdempotencia;
 IF @nVentaId IS NOT NULL
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM comercial.Venta WHERE venta_id=@nVentaId AND uot_id=@nUotId AND almacen_id=@nAlmacenId
      AND ISNULL(cliente_persona_id,-1)=ISNULL(@nClientePersonaId,-1)
      AND ISNULL(cliente_empresa_id,-1)=ISNULL(@nClienteEmpresaId,-1))
  BEGIN SET @nVentaId=NULL;SET @cMensaje=N'La solicitud ya fue utilizada para otra venta.';RETURN;END;
  SET @bResultado=1; SET @cMensaje=N'La venta ya fue registrada correctamente.'; RETURN;
 END;
 IF EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad')
  WHERE productoId IS NULL OR cantidad IS NULL OR cantidad<=0)
 BEGIN SET @cMensaje=N'La venta debe incluir productos y cantidades válidos.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
  DECLARE @Detalle TABLE(producto_id BIGINT PRIMARY KEY,cantidad DECIMAL(19,3),precio_id BIGINT,precio_inicial DECIMAL(19,4),precio_venta DECIMAL(19,4),moneda CHAR(3));
  ;WITH Raw AS(
      SELECT productoId,cantidad FROM OPENJSON(@cDetalleJson)
      WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad')
  ), Agrupado AS(
      SELECT productoId,SUM(cantidad) cantidad FROM Raw GROUP BY productoId
  )
  INSERT @Detalle(producto_id,cantidad,precio_id,precio_inicial,precio_venta,moneda)
  SELECT D.productoId,D.cantidad,P.producto_precio_id,P.precio_inicial,P.precio_venta,P.moneda
  FROM Agrupado D
  OUTER APPLY(SELECT TOP(1) PP.producto_precio_id,PP.precio_inicial,PP.precio_venta,PP.moneda
              FROM logistica.ProductoPrecio PP
              WHERE PP.producto_id=D.productoId AND PP.estado=1 AND PP.fecha_hasta IS NULL AND PP.uot_id=@nUotId
              ORDER BY CASE WHEN PP.uot_id=@nUotId THEN 0 ELSE 1 END,PP.version DESC,PP.producto_precio_id DESC) P;

  IF EXISTS(SELECT 1 FROM @Detalle D LEFT JOIN logistica.Producto P ON P.producto_id=D.producto_id LEFT JOIN logistica.ProductoUOTPolitica U ON U.producto_id=D.producto_id AND U.uot_id=@nUotId WHERE P.estado<>1 OR P.producto_id IS NULL OR U.estado IS NULL OR U.estado<>1 OR U.permite_venta<>1) THROW 51063,N'VENTA_PRODUCTO_NO_HABILITADO',1;
  IF EXISTS(SELECT 1 FROM @Detalle D
            LEFT JOIN logistica.Producto P ON P.producto_id=D.producto_id
            WHERE P.producto_id IS NULL OR P.estado=0 OR P.permite_venta=0)
       THROW 51063,N'VENTA_PRODUCTO_NO_VENDIBLE',1;
  IF EXISTS(SELECT 1 FROM @Detalle WHERE producto_id IS NULL OR cantidad IS NULL OR cantidad<=0 OR precio_id IS NULL) THROW 51060,N'VENTA_DETALLE_INVALIDO',1;
  IF EXISTS(SELECT 1 FROM @Detalle D LEFT JOIN logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK) ON S.almacen_id=@nAlmacenId AND S.producto_id=D.producto_id WHERE ISNULL(S.stock_disponible,0)<D.cantidad) THROW 51061,N'VENTA_STOCK_INSUFICIENTE',1;
  IF (SELECT COUNT(DISTINCT moneda) FROM @Detalle)<>1 THROW 51062,N'VENTA_MONEDA_MIXTA',1;

  DECLARE @Moneda CHAR(3)=(SELECT TOP(1) moneda FROM @Detalle);
  DECLARE @Subtotal DECIMAL(19,4)=(SELECT SUM(CONVERT(DECIMAL(19,4),cantidad*precio_venta)) FROM @Detalle);
  INSERT comercial.Venta(uot_id,almacen_id,cliente_persona_id,cliente_empresa_id,vendedor_usuario_id,clave_idempotencia,fecha_reserva_hasta,moneda,subtotal,descuento,impuesto,total,estado_venta,observacion,estado)
  VALUES(@nUotId,@nAlmacenId,@nClientePersonaId,@nClienteEmpresaId,@nUsuarioId,@gClaveIdempotencia,@dReservaHasta,@Moneda,@Subtotal,0,0,@Subtotal,CASE WHEN @bSeparar=1 THEN 'SEPARADA' ELSE 'REGISTRADA' END,@cObservacion,1);
  SET @nVentaId=SCOPE_IDENTITY();
  INSERT comercial.DetalleVenta(venta_id,producto_id,producto_precio_id,cantidad,precio_inicial_referencia,precio_unitario,descuento_unitario,estado)
  SELECT @nVentaId,producto_id,precio_id,cantidad,precio_inicial,precio_venta,0,1 FROM @Detalle;
  IF @bSeparar=1
  BEGIN
    INSERT logistica.ReservaStock(detalle_venta_id,almacen_id,producto_id,cantidad,fecha_expiracion,estado_reserva,estado)
    SELECT DV.detalle_venta_id,@nAlmacenId,DV.producto_id,DV.cantidad,@dReservaHasta,'ACTIVA',1 FROM comercial.DetalleVenta DV WHERE DV.venta_id=@nVentaId AND DV.estado=1;
    UPDATE S SET stock_reservado=S.stock_reservado+D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
    FROM logistica.AlmacenProductoStock S JOIN @Detalle D ON D.producto_id=S.producto_id WHERE S.almacen_id=@nAlmacenId;
  END;
  COMMIT; SET @bResultado=1; SET @cMensaje=CASE WHEN @bSeparar=1 THEN N'Venta separada correctamente.' ELSE N'Venta registrada correctamente.' END;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK; SET @nVentaId=NULL;
  SET @cMensaje=CASE
      WHEN ERROR_MESSAGE() LIKE '%VENTA_PRODUCTO_NO_HABILITADO%' THEN N'Uno o más productos no están habilitados para venta en esta UOT.'
      WHEN ERROR_MESSAGE() LIKE '%VENTA_PRODUCTO_NO_VENDIBLE%' THEN N'El producto es exclusivamente operativo y no puede venderse.'
      WHEN ERROR_MESSAGE() LIKE '%VENTA_STOCK_INSUFICIENTE%' THEN N'No hay stock suficiente para completar la venta.'
      WHEN ERROR_MESSAGE() LIKE '%VENTA_DETALLE_INVALIDO%' THEN N'Uno o más productos no tienen cantidad o precio vigente válido.'
      WHEN ERROR_MESSAGE() LIKE '%VENTA_MONEDA_MIXTA%' THEN N'Los productos de una venta deben utilizar la misma moneda.'
      ELSE N'No se pudo registrar la venta.' END;
 END CATCH;
END;
GO
