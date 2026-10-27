IF OBJECT_ID(N'[logistica].[PA_UOT_Ins_TransferirRecursos]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_UOT_Ins_TransferirRecursos];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_UOT_Ins_TransferirRecursos
' Descripción             : Transfiere recursos entre unidades organizativas territoriales.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Migración independiente a Flyway; lógica original conservada.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Ejemplo orientativo: sustituir identificadores y valores por datos válidos.
    DECLARE
        @nMovimientoSalidaId BIGINT,
        @nMovimientoEntradaId BIGINT,
        @nProductosTransferidos INT,
        @nBienesTransferidos INT,
        @nSuministrosTransferidos INT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300),
        @cCodigoRespuesta VARCHAR(60),
        @nHttpRespuesta SMALLINT;
    EXEC [logistica].[PA_UOT_Ins_TransferirRecursos]
        @nUsuarioId = 0,
        @nUotOrigenId = 0,
        @nUotDestinoId = 0,
        @nAlmacenOrigenId = 0,
        @nAlmacenDestinoId = 0,
        @bTransferirStock = 0,
        @cBienesJson = N'',
        @cSuministrosJson = N'',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cMotivo = N'',
        @nMovimientoSalidaId = @nMovimientoSalidaId OUTPUT,
        @nMovimientoEntradaId = @nMovimientoEntradaId OUTPUT,
        @nProductosTransferidos = @nProductosTransferidos OUTPUT,
        @nBienesTransferidos = @nBienesTransferidos OUTPUT,
        @nSuministrosTransferidos = @nSuministrosTransferidos OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT,
        @cCodigoRespuesta = @cCodigoRespuesta OUTPUT,
        @nHttpRespuesta = @nHttpRespuesta OUTPUT;
    SELECT @nMovimientoSalidaId, @nMovimientoEntradaId, @nProductosTransferidos, @nBienesTransferidos, @nSuministrosTransferidos, @bResultado, @cMensaje, @cCodigoRespuesta, @nHttpRespuesta;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_UOT_Ins_TransferirRecursos
 @nUsuarioId BIGINT,@nUotOrigenId BIGINT,@nUotDestinoId BIGINT,@nAlmacenOrigenId BIGINT=NULL,@nAlmacenDestinoId BIGINT=NULL,
 @bTransferirStock BIT=0,@cBienesJson NVARCHAR(MAX)=N'[]',@cSuministrosJson NVARCHAR(MAX)=N'[]',@gClaveIdempotencia UNIQUEIDENTIFIER,@cMotivo NVARCHAR(500),
 @nMovimientoSalidaId BIGINT OUTPUT,@nMovimientoEntradaId BIGINT OUTPUT,@nProductosTransferidos INT OUTPUT,@nBienesTransferidos INT OUTPUT,@nSuministrosTransferidos INT OUTPUT,
 @bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @nMovimientoSalidaId=NULL,@nMovimientoEntradaId=NULL,@nProductosTransferidos=0,@nBienesTransferidos=0,@nSuministrosTransferidos=0,@bResultado=0,@cMensaje=N'No se pudieron transferir los recursos.',@cCodigoRespuesta='UOT_RECURSOS_NO_TRANSFERIDOS',@nHttpRespuesta=400;
 SET @cMotivo=NULLIF(LTRIM(RTRIM(@cMotivo)),N'');
 IF @nUotOrigenId=@nUotDestinoId BEGIN SET @cMensaje=N'Seleccione una UOT de destino diferente.'; RETURN 1; END;
 IF @cMotivo IS NULL OR @gClaveIdempotencia IS NULL BEGIN SET @cMensaje=N'Complete los datos de la transferencia.'; RETURN 1; END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotOrigenId,'UOT_RETIRAR')=0 OR seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotDestinoId,'UOT_EDITAR')=0 BEGIN SET @cMensaje=N'No tiene permiso para transferir entre estas UOT.'; RETURN 1; END;
 IF NOT EXISTS(SELECT 1 FROM org.UOT WHERE uot_id=@nUotDestinoId AND estado=1) BEGIN SET @cMensaje=N'La UOT de destino no esta disponible.'; RETURN 1; END;
 SET @cBienesJson=COALESCE(@cBienesJson,N'[]'); SET @cSuministrosJson=COALESCE(@cSuministrosJson,N'[]');
 IF ISJSON(@cBienesJson)<>1 OR ISJSON(@cSuministrosJson)<>1 BEGIN SET @cMensaje=N'La seleccion de recursos no es valida.'; RETURN 1; END;
 IF @bTransferirStock=1
 BEGIN
   IF @nAlmacenOrigenId IS NULL OR @nAlmacenDestinoId IS NULL BEGIN SET @cMensaje=N'Seleccione los almacenes para transferir stock.'; RETURN 1; END;
   IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenOrigenId AND uot_propietaria_id=@nUotOrigenId AND estado=1) OR NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenDestinoId AND uot_propietaria_id=@nUotDestinoId AND estado=1) BEGIN SET @cMensaje=N'Los almacenes no corresponden a las UOT seleccionadas.'; RETURN 1; END;
   IF EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@nAlmacenOrigenId AND stock_reservado<>0) BEGIN SET @cMensaje=N'Libere las reservas de stock antes de transferir.'; RETURN 1; END;
 END;
 DECLARE @Bienes TABLE(id BIGINT PRIMARY KEY); INSERT @Bienes SELECT DISTINCT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cBienesJson) WHERE TRY_CONVERT(BIGINT,[value]) IS NOT NULL;
 DECLARE @Suministros TABLE(id BIGINT PRIMARY KEY); INSERT @Suministros SELECT DISTINCT TRY_CONVERT(BIGINT,[value]) FROM OPENJSON(@cSuministrosJson) WHERE TRY_CONVERT(BIGINT,[value]) IS NOT NULL;
 IF @bTransferirStock=0 AND NOT EXISTS(SELECT 1 FROM @Bienes) AND NOT EXISTS(SELECT 1 FROM @Suministros) BEGIN SET @cMensaje=N'Seleccione recursos para transferir.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM @Bienes X LEFT JOIN logistica.BienInventario B ON B.bien_inventario_id=X.id AND B.uot_id=@nUotOrigenId AND B.estado=1 WHERE B.bien_inventario_id IS NULL) BEGIN SET @cMensaje=N'Uno de los bienes no pertenece a la UOT de origen.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM @Bienes X JOIN logistica.RecursoProgramado RP ON RP.bien_inventario_id=X.id AND RP.estado=1 AND RP.estado_proceso NOT IN('COMPLETADO','CANCELADO')) BEGIN SET @cMensaje=N'Hay bienes asignados a actividades pendientes.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM @Suministros X LEFT JOIN logistica.Suministro S ON S.suministro_id=X.id AND S.uot_id=@nUotOrigenId AND S.estado=1 WHERE S.suministro_id IS NULL) BEGIN SET @cMensaje=N'Uno de los suministros no pertenece a la UOT de origen.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM @Suministros X JOIN logistica.SuministroSaldo K ON K.suministro_id=X.id WHERE K.stock_reservado<>0) BEGIN SET @cMensaje=N'Libere las reservas de suministros antes de transferir.'; RETURN 1; END;
 IF EXISTS(SELECT 1 FROM @Suministros X JOIN logistica.RecursoProgramado RP ON RP.suministro_id=X.id AND RP.estado=1 AND RP.estado_proceso NOT IN('COMPLETADO','CANCELADO')) BEGIN SET @cMensaje=N'Hay suministros asignados a actividades pendientes.'; RETURN 1; END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
  IF @bTransferirStock=1 AND EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@nAlmacenOrigenId AND stock_actual>0)
  BEGIN
    DECLARE @gEntrada UNIQUEIDENTIFIER=NEWID(),@Ahora DATETIME2(0)=SYSUTCDATETIME();
    INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,documento_referencia,clave_idempotencia,fecha_hora,usuario_id,observacion,estado)
    VALUES(@nAlmacenOrigenId,@nUotOrigenId,'TRANSFERENCIA','S',CONCAT('UOT-',@nUotOrigenId,'-',@nUotDestinoId),@gClaveIdempotencia,@Ahora,@nUsuarioId,@cMotivo,1);
    SET @nMovimientoSalidaId=SCOPE_IDENTITY();
    INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,movimiento_relacionado_id,documento_referencia,clave_idempotencia,fecha_hora,usuario_id,observacion,estado)
    VALUES(@nAlmacenDestinoId,@nUotDestinoId,'TRANSFERENCIA','E',@nMovimientoSalidaId,CONCAT('UOT-',@nUotOrigenId,'-',@nUotDestinoId),@gEntrada,@Ahora,@nUsuarioId,@cMotivo,1);
    SET @nMovimientoEntradaId=SCOPE_IDENTITY(); UPDATE logistica.MovimientoInventario SET movimiento_relacionado_id=@nMovimientoEntradaId WHERE movimiento_inventario_id=@nMovimientoSalidaId;
    DECLARE @Stock TABLE(producto_id BIGINT PRIMARY KEY,cantidad DECIMAL(19,3),stock_minimo DECIMAL(19,3)); INSERT @Stock SELECT producto_id,stock_actual,stock_minimo FROM logistica.AlmacenProductoStock WHERE almacen_id=@nAlmacenOrigenId AND stock_actual>0;
    INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad) SELECT @nMovimientoSalidaId,producto_id,cantidad FROM @Stock;
    INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad) SELECT @nMovimientoEntradaId,producto_id,cantidad FROM @Stock;
    SELECT @nProductosTransferidos=COUNT(*) FROM @Stock;
    MERGE logistica.AlmacenProductoStock T USING @Stock S ON T.almacen_id=@nAlmacenDestinoId AND T.producto_id=S.producto_id
    WHEN MATCHED THEN UPDATE SET stock_actual=T.stock_actual+S.cantidad,fecha_actualizacion=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT(almacen_id,producto_id,stock_actual,stock_reservado,stock_minimo,fecha_actualizacion) VALUES(@nAlmacenDestinoId,S.producto_id,S.cantidad,0,S.stock_minimo,SYSUTCDATETIME());
    UPDATE APS SET stock_actual=0,fecha_actualizacion=SYSUTCDATETIME() FROM logistica.AlmacenProductoStock APS JOIN @Stock S ON S.producto_id=APS.producto_id WHERE APS.almacen_id=@nAlmacenOrigenId;
  END;
  UPDATE B SET uot_id=@nUotDestinoId,empresa_id=COALESCE(U.empresa_legacy_id,B.empresa_id) FROM logistica.BienInventario B JOIN @Bienes X ON X.id=B.bien_inventario_id CROSS JOIN org.UOT U WHERE U.uot_id=@nUotDestinoId;
  SET @nBienesTransferidos=@@ROWCOUNT;

  DECLARE @Sid BIGINT,@Codigo VARCHAR(40),@Nombre NVARCHAR(150),@Unidad VARCHAR(20),@Min DECIMAL(19,3),@Cant DECIMAL(19,3),@Target BIGINT,@MovOut BIGINT;
  DECLARE C CURSOR LOCAL FAST_FORWARD FOR SELECT S.suministro_id,S.codigo,S.nombre,S.unidad_medida,S.stock_minimo,COALESCE(K.stock_actual,0) FROM logistica.Suministro S JOIN @Suministros X ON X.id=S.suministro_id LEFT JOIN logistica.SuministroSaldo K ON K.suministro_id=S.suministro_id;
  OPEN C; FETCH NEXT FROM C INTO @Sid,@Codigo,@Nombre,@Unidad,@Min,@Cant;
  WHILE @@FETCH_STATUS=0
  BEGIN
    SELECT @Target=NULL; SELECT @Target=suministro_id FROM logistica.Suministro WHERE uot_id=@nUotDestinoId AND codigo=@Codigo AND estado=1;
    IF @Target IS NULL BEGIN INSERT logistica.Suministro(uot_id,codigo,nombre,unidad_medida,estado,stock_minimo) VALUES(@nUotDestinoId,@Codigo,@Nombre,@Unidad,1,@Min); SET @Target=SCOPE_IDENTITY(); INSERT logistica.SuministroSaldo(suministro_id,stock_actual,stock_reservado,fecha_actualizacion) VALUES(@Target,0,0,SYSUTCDATETIME()); END;
    IF @Cant>0
    BEGIN
      INSERT logistica.SuministroMovimiento(suministro_id,uot_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,documento_referencia,observacion,estado) VALUES(@Sid,@nUotOrigenId,'TRANSFERENCIA_SALIDA',@Cant,SYSUTCDATETIME(),@nUsuarioId,CONCAT('UOT-',@nUotOrigenId,'-',@nUotDestinoId),@cMotivo,1);
      SET @MovOut=SCOPE_IDENTITY();
      INSERT logistica.SuministroMovimiento(suministro_id,uot_id,tipo_movimiento,cantidad,fecha_hora,usuario_id,documento_referencia,observacion,estado,movimiento_origen_id) VALUES(@Target,@nUotDestinoId,'TRANSFERENCIA_ENTRADA',@Cant,SYSUTCDATETIME(),@nUsuarioId,CONCAT('UOT-',@nUotOrigenId,'-',@nUotDestinoId),@cMotivo,1,@MovOut);
    END;
    SET @nSuministrosTransferidos=@nSuministrosTransferidos+1; FETCH NEXT FROM C INTO @Sid,@Codigo,@Nombre,@Unidad,@Min,@Cant;
  END; CLOSE C; DEALLOCATE C;
  COMMIT; SELECT @bResultado=1,@cMensaje=N'Recursos transferidos.',@cCodigoRespuesta='UOT_RECURSOS_TRANSFERIDOS',@nHttpRespuesta=200; RETURN 0;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; SET @cMensaje=N'No se pudieron transferir los recursos.'; RETURN 1; END CATCH;
END;
GO
