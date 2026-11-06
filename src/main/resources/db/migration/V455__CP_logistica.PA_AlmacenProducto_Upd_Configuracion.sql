/* DESCO: gestion local del producto-almacen.
 Ejemplo: ejecutar EDITAR con stock minimo y motivo, o DESACTIVAR/REACTIVAR/RETIRAR con motivo y clave nueva. */
IF OBJECT_ID(N'logistica.PA_AlmacenProducto_Upd_Configuracion',N'P') IS NOT NULL DROP PROCEDURE logistica.PA_AlmacenProducto_Upd_Configuracion;
GO
IF OBJECT_ID(N'logistica.PA_AlmacenProducto_Upd_Configuracion', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_AlmacenProducto_Upd_Configuracion;
GO
CREATE PROCEDURE logistica.PA_AlmacenProducto_Upd_Configuracion
 @nUsuarioId BIGINT,@nSesionUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@nProductoId BIGINT,
 @cOperacion VARCHAR(15),@nStockMinimo DECIMAL(19,3)=NULL,@cMotivo NVARCHAR(500),@gClaveIdempotencia UNIQUEIDENTIFIER,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @bResultado=0,@cMensaje=N'No se pudo gestionar el producto del almacen.',@cCodigoRespuesta='ALMACEN_PRODUCTO_NO_ACTUALIZADO',@nHttpRespuesta=400;
 SELECT @cOperacion=UPPER(LTRIM(RTRIM(@cOperacion))),@cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
 IF @cOperacion NOT IN('EDITAR','DESACTIVAR','REACTIVAR','RETIRAR') OR @cMotivo IS NULL OR @gClaveIdempotencia IS NULL
 BEGIN SET @cMensaje=N'Indique la operacion, motivo y clave de solicitud.';RETURN;END;
 IF @cOperacion='EDITAR' AND (@nStockMinimo IS NULL OR @nStockMinimo<0)
 BEGIN SET @cMensaje=N'Ingrese un stock minimo valido.';RETURN;END;
 DECLARE @Resuelta BIGINT=@nUotId,@General BIT,@Ok BIT,@Msg NVARCHAR(300);
 EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuarioId=@nUsuarioId,@nSesionUsuarioId=@nSesionUsuarioId,@nUotSolicitada=@nUotId,@cCodigoPermiso='ALMACENES_MOVIMIENTO',@bRequiereUot=1,@nUotId=@Resuelta OUTPUT,@bModoGeneral=@General OUTPUT,@bResultado=@Ok OUTPUT,@cMensaje=@Msg OUTPUT;
 IF ISNULL(@Ok,0)=0 BEGIN SELECT @cMensaje=COALESCE(@Msg,N'No tiene permiso en esta UOT.'),@nHttpRespuesta=403;RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenId AND uot_propietaria_id=@Resuelta AND estado=1)
 BEGIN SELECT @cMensaje=N'Solo la UOT propietaria puede gestionar la configuracion del producto en este almacen.',@nHttpRespuesta=403;RETURN;END;
 DECLARE @Saldo DECIMAL(19,3),@Reservado DECIMAL(19,3),@Minimo DECIMAL(19,3),@Estado BIT,@NuevoEstado BIT,
 @Hash VARBINARY(32)=HASHBYTES('SHA2_256',CONCAT(@nAlmacenId,'|',@nProductoId,'|',@cOperacion,'|',@nStockMinimo,'|',@cMotivo));
 BEGIN TRY
  BEGIN TRANSACTION;
  -- La misma cerradura del saldo serializa contra reservas, movimientos y otras modificaciones.
  SELECT @Saldo=stock_actual,@Reservado=stock_reservado,@Minimo=stock_minimo,@Estado=estado FROM logistica.AlmacenProductoStock WITH(UPDLOCK,HOLDLOCK) WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId;
  IF EXISTS(SELECT 1 FROM logistica.AlmacenProductoEvento WITH(UPDLOCK,HOLDLOCK) WHERE clave_idempotencia=@gClaveIdempotencia)
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoEvento WHERE clave_idempotencia=@gClaveIdempotencia AND usuario_id=@nUsuarioId AND solicitud_sha256=@Hash)
    THROW 51080,N'La clave de solicitud ya pertenece a otra operacion.',1;
   COMMIT;SELECT @bResultado=1,@cMensaje=N'La solicitud ya fue procesada.',@cCodigoRespuesta='ALMACEN_PRODUCTO_ACTUALIZADO',@nHttpRespuesta=200;RETURN;
  END;
  IF @Estado IS NULL BEGIN SET @nHttpRespuesta=404;THROW 51080,N'El producto no esta registrado en este almacen.',1;END;
  IF @cOperacion IN('DESACTIVAR','RETIRAR') AND (@Saldo<>0 OR @Reservado<>0)
    THROW 51080,N'No puede desactivar o retirar un producto con stock o reservas. Registre primero los movimientos correspondientes.',1;
  IF @cOperacion='DESACTIVAR' AND EXISTS(SELECT 1 FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId AND estado_proceso IN('PENDIENTE','APROBADA','ENTREGADA'))
    THROW 51080,N'El producto tiene programaciones pendientes en este almacen.',1;
  IF @cOperacion='RETIRAR' AND logistica.FN_AlmacenProducto_TieneHistorial(@nAlmacenId,@nProductoId)=1
    THROW 51080,N'El producto tiene historial operativo en este almacen. Puede desactivarlo cuando su saldo sea cero.',1;
  IF @cOperacion='REACTIVAR' AND NOT EXISTS(SELECT 1 FROM logistica.Producto WITH(UPDLOCK,HOLDLOCK) WHERE producto_id=@nProductoId AND estado=1)
    THROW 51080,N'Active primero el producto en el catalogo general.',1;
  SET @NuevoEstado=CASE @cOperacion WHEN 'DESACTIVAR' THEN 0 WHEN 'REACTIVAR' THEN 1 WHEN 'RETIRAR' THEN NULL ELSE @Estado END;
  IF @cOperacion='RETIRAR' DELETE logistica.AlmacenProductoStock WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId;
  ELSE UPDATE logistica.AlmacenProductoStock SET stock_minimo=CASE WHEN @cOperacion='EDITAR' THEN @nStockMinimo ELSE stock_minimo END,estado=@NuevoEstado,fecha_actualizacion=SYSUTCDATETIME() WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId;
  INSERT logistica.AlmacenProductoEvento(almacen_id,producto_id,operacion,stock_minimo_anterior,stock_minimo_nuevo,estado_anterior,estado_nuevo,motivo,usuario_id,clave_idempotencia,solicitud_sha256)
  VALUES(@nAlmacenId,@nProductoId,@cOperacion,@Minimo,CASE WHEN @cOperacion='EDITAR' THEN @nStockMinimo WHEN @cOperacion='RETIRAR' THEN NULL ELSE @Minimo END,@Estado,@NuevoEstado,@cMotivo,@nUsuarioId,@gClaveIdempotencia,@Hash);
  COMMIT;
  SELECT @bResultado=1,@cMensaje=CASE @cOperacion WHEN 'EDITAR' THEN N'Configuracion actualizada.' WHEN 'DESACTIVAR' THEN N'Producto desactivado en este almacen.' WHEN 'REACTIVAR' THEN N'Producto reactivado en este almacen.' ELSE N'Asociacion retirada; el producto del catalogo se conserva.' END,@cCodigoRespuesta='ALMACEN_PRODUCTO_ACTUALIZADO',@nHttpRespuesta=200;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  IF ERROR_NUMBER()=51080 BEGIN SET @cMensaje=ERROR_MESSAGE();IF @nHttpRespuesta<>404 SET @nHttpRespuesta=409;END;
 END CATCH;
END;
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Gestiona stock minimo, estado y retiro sin alterar cantidades ni precios. Serializa con reservas, valida UOT propietaria, preserva historial e idempotencia con motivo obligatorio.',@level0type=N'SCHEMA',@level0name=N'logistica',@level1type=N'PROCEDURE',@level1name=N'PA_AlmacenProducto_Upd_Configuracion';
GO
