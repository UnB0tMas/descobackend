IF OBJECT_ID(N'[logistica].[PA_EntregaTecnica_Ins_Registrar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_EntregaTecnica_Ins_Registrar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_EntregaTecnica_Ins_Registrar
' Descripción             : Registra entrega técnica con salida de Kardex sin venta.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Actualización de controles de uso interno y UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nEntregaTecnicaId BIGINT,
            @nMovimientoInventarioId BIGINT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300),
            @cCodigoRespuesta VARCHAR(60),
            @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_EntregaTecnica_Ins_Registrar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nAlmacenId = 0,
        @nEmpleadoId = 0,
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cDetalleJson = N'[]',
        @cMotivo = N'',
        @cObservacion = N'',
        @nEntregaTecnicaId = @nEntregaTecnicaId OUTPUT,
        @nMovimientoInventarioId = @nMovimientoInventarioId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nEntregaTecnicaId, @nMovimientoInventarioId, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
IF OBJECT_ID(N'logistica.PA_EntregaTecnica_Ins_Registrar', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_EntregaTecnica_Ins_Registrar;
GO
CREATE PROCEDURE logistica.PA_EntregaTecnica_Ins_Registrar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@nEmpleadoId BIGINT,
 @gClaveIdempotencia UNIQUEIDENTIFIER,@cDetalleJson NVARCHAR(MAX),@cMotivo NVARCHAR(300),@cObservacion NVARCHAR(500)=NULL,
 @nEntregaTecnicaId BIGINT OUTPUT,@nMovimientoInventarioId BIGINT OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @nEntregaTecnicaId=NULL,@nMovimientoInventarioId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la entrega técnica.',
        @cCodigoRespuesta='ENTREGA_TECNICA_NO_REGISTRADA',@nHttpRespuesta=400;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N''); SET @cObservacion=NULLIF(LTRIM(RTRIM(@cObservacion)),N'');
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'VENTAS_ENTREGA_TECNICA')=0
 BEGIN SET @cMensaje=N'No tiene permiso para registrar entregas técnicas.'; SET @cCodigoRespuesta='NO_AUTORIZADO'; SET @nHttpRespuesta=403; RETURN 1; END;
 IF @gClaveIdempotencia IS NULL OR @cMotivo IS NULL OR ISJSON(@cDetalleJson)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson))
 BEGIN SET @cMensaje=N'La entrega debe incluir empleado, motivo y productos válidos.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen A WHERE A.almacen_id=@nAlmacenId AND A.uot_propietaria_id=@nUotId AND A.estado=1) BEGIN SET @cMensaje=N'El almacén no pertenece a la UOT seleccionada.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenId AND uot_id=@nUotId AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1)
 BEGIN SET @cMensaje=N'La UOT no puede retirar productos del almacén seleccionado.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM org.Empleado E JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id AND EU.uot_id=@nUotId AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME()) AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())) WHERE E.empleado_id=@nEmpleadoId AND E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())))
 BEGIN SET @cMensaje=N'El empleado seleccionado no está habilitado en la UOT.'; RETURN 1; END;

 SELECT @nEntregaTecnicaId=entrega_tecnica_id,@nMovimientoInventarioId=movimiento_inventario_id
 FROM logistica.EntregaTecnica WHERE clave_idempotencia=@gClaveIdempotencia;
 IF @nEntregaTecnicaId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM logistica.EntregaTecnica
 WHERE entrega_tecnica_id=@nEntregaTecnicaId AND uot_id=@nUotId AND almacen_id=@nAlmacenId
 AND empleado_id=@nEmpleadoId AND motivo=@cMotivo)
 BEGIN SET @nEntregaTecnicaId=NULL;SET @nMovimientoInventarioId=NULL;SET @cMensaje=N'La solicitud ya fue utilizada para otra entrega.';RETURN 1;END;
 IF @nEntregaTecnicaId IS NOT NULL
 BEGIN SELECT @bResultado=1,@cMensaje=N'La entrega técnica ya fue registrada correctamente.',@cCodigoRespuesta='ENTREGA_TECNICA_REGISTRADA',@nHttpRespuesta=200; RETURN 0; END;

 BEGIN TRY
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
   DECLARE @Detalle TABLE(producto_id BIGINT PRIMARY KEY,cantidad DECIMAL(19,3),costo DECIMAL(19,4) NULL,moneda CHAR(3) NULL);
   ;WITH Raw AS(
      SELECT productoId,cantidad FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad')
   ), Agrupado AS(
      SELECT productoId,SUM(cantidad) cantidad FROM Raw GROUP BY productoId
   )
   INSERT @Detalle(producto_id,cantidad,costo,moneda)
   SELECT D.productoId,D.cantidad,PP.precio_inicial,PP.moneda
   FROM Agrupado D
   LEFT JOIN logistica.Producto P ON P.producto_id=D.productoId AND P.estado=1
   OUTER APPLY(SELECT TOP(1) X.precio_inicial,X.moneda FROM logistica.ProductoPrecio X
               WHERE X.producto_id=D.productoId AND X.estado=1 AND X.fecha_hasta IS NULL AND (X.uot_id=@nUotId OR X.uot_id IS NULL)
               ORDER BY CASE WHEN X.uot_id=@nUotId THEN 0 ELSE 1 END,X.version DESC,X.producto_precio_id DESC) PP
   WHERE P.producto_id IS NOT NULL;

   IF EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad') WHERE productoId IS NULL OR cantidad IS NULL OR cantidad<=0)
      OR (SELECT COUNT(DISTINCT productoId) FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId'))<>(SELECT COUNT(*) FROM @Detalle)
      THROW 51080,N'ENTREGA_TECNICA_DETALLE_INVALIDO',1;

   IF EXISTS(SELECT 1 FROM @Detalle D LEFT JOIN logistica.ProductoUOTPolitica P ON P.uot_id=@nUotId AND P.producto_id=D.producto_id WHERE P.estado IS NULL OR P.estado<>1 OR P.permite_uso_interno<>1) THROW 51082,N'ENTREGA_TECNICA_NO_HABILITADO',1;

   IF EXISTS(SELECT 1 FROM @Detalle D LEFT JOIN logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK)
             ON S.almacen_id=@nAlmacenId AND S.producto_id=D.producto_id WHERE ISNULL(S.stock_disponible,0)<D.cantidad)
      THROW 51081,N'ENTREGA_TECNICA_STOCK_INSUFICIENTE',1;

   INSERT logistica.EntregaTecnica(uot_id,almacen_id,empleado_id,usuario_entrega_id,clave_idempotencia,motivo,observacion,estado)
   VALUES(@nUotId,@nAlmacenId,@nEmpleadoId,@nUsuarioId,@gClaveIdempotencia,@cMotivo,@cObservacion,1);
   SET @nEntregaTecnicaId=SCOPE_IDENTITY();

   INSERT logistica.EntregaTecnicaDetalle(entrega_tecnica_id,producto_id,cantidad,estado)
   SELECT @nEntregaTecnicaId,producto_id,cantidad,1 FROM @Detalle;

   INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,documento_referencia,clave_idempotencia,usuario_id,observacion,estado)
   VALUES(@nAlmacenId,@nUotId,'CONSUMO','S',CONCAT(N'ENTREGA-TECNICA-',@nEntregaTecnicaId),@gClaveIdempotencia,@nUsuarioId,
          CONCAT(N'Entrega técnica a empleado ',@nEmpleadoId,N'. ',COALESCE(@cObservacion,N'')),1);
   SET @nMovimientoInventarioId=SCOPE_IDENTITY();

   INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda)
   SELECT @nMovimientoInventarioId,producto_id,cantidad,costo,moneda FROM @Detalle;

   UPDATE S SET stock_actual=S.stock_actual-D.cantidad,fecha_actualizacion=SYSUTCDATETIME()
   FROM logistica.AlmacenProductoStock S JOIN @Detalle D ON D.producto_id=S.producto_id
   WHERE S.almacen_id=@nAlmacenId;

   UPDATE logistica.EntregaTecnica SET movimiento_inventario_id=@nMovimientoInventarioId
   WHERE entrega_tecnica_id=@nEntregaTecnicaId;

   COMMIT;
   SELECT @bResultado=1,@cMensaje=N'Entrega técnica registrada correctamente.',@cCodigoRespuesta='ENTREGA_TECNICA_REGISTRADA',@nHttpRespuesta=201;
   RETURN 0;
 END TRY
 BEGIN CATCH
   IF XACT_STATE()<>0 ROLLBACK;
   SELECT @nEntregaTecnicaId=NULL,@nMovimientoInventarioId=NULL;
   SET @cMensaje=CASE WHEN ERROR_NUMBER()=51120 THEN ERROR_MESSAGE()
      WHEN ERROR_MESSAGE() LIKE '%ENTREGA_TECNICA_NO_HABILITADO%' THEN N'Uno o más productos no están habilitados para uso interno.'
      WHEN ERROR_MESSAGE() LIKE '%ENTREGA_TECNICA_STOCK_INSUFICIENTE%' THEN N'No hay stock suficiente para completar la entrega técnica.'
      WHEN ERROR_MESSAGE() LIKE '%ENTREGA_TECNICA_DETALLE_INVALIDO%' THEN N'Uno o más productos de la entrega no son válidos.'
      WHEN ERROR_NUMBER() IN(2601,2627) THEN N'La entrega ya fue procesada o contiene datos duplicados.'
      ELSE N'No se pudo registrar la entrega técnica.' END;
   RETURN 1;
 END CATCH;
END;
GO
