IF OBJECT_ID(N'[logistica].[PA_Almacen_Ins_TransferirStock]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_Almacen_Ins_TransferirStock];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_Almacen_Ins_TransferirStock
' Descripción             : Transfiere stock entre almacenes con dos movimientos trazables.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de transferencias autorizadas entre almacenes.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nTransferenciaId BIGINT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_Almacen_Ins_TransferirStock]
        @nUsuarioId = 0,
        @nAlmacenOrigenId = 0,
        @nAlmacenDestinoId = 0,
        @cDetalleJson = N'[]',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cObservacion = N'',
        @nTransferenciaId = @nTransferenciaId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nTransferenciaId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_Almacen_Ins_TransferirStock
 @nUsuarioId BIGINT,@nAlmacenOrigenId BIGINT,@nAlmacenDestinoId BIGINT,
 @cDetalleJson NVARCHAR(MAX),@gClaveIdempotencia UNIQUEIDENTIFIER,
 @cObservacion NVARCHAR(300)=NULL,
 @nTransferenciaId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @nTransferenciaId=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la transferencia.';
 DECLARE @UotOrigen BIGINT,@UotDestino BIGINT,@MovS BIGINT,@MovE BIGINT,
  @Ok BIT,@Msg NVARCHAR(300),@ClaveSalida UNIQUEIDENTIFIER=NEWID(),@ClaveEntrada UNIQUEIDENTIFIER=NEWID(),
  @DetalleHash VARBINARY(32);
 SELECT @UotOrigen=uot_propietaria_id FROM logistica.Almacen WHERE almacen_id=@nAlmacenOrigenId AND estado=1;
 SELECT @UotDestino=uot_propietaria_id FROM logistica.Almacen WHERE almacen_id=@nAlmacenDestinoId AND estado=1;
 IF @UotOrigen IS NULL OR @UotDestino IS NULL OR @nAlmacenOrigenId=@nAlmacenDestinoId
 BEGIN SET @cMensaje=N'Seleccione almacenes de origen y destino diferentes y activos.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UotOrigen,'ALMACENES_MOVIMIENTO')=0 OR
    seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@UotDestino,'ALMACENES_MOVIMIENTO')=0
 BEGIN SET @cMensaje=N'No tiene autorización para operar ambos almacenes.';RETURN;END;
 IF @gClaveIdempotencia IS NULL OR ISJSON(@cDetalleJson)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson))
 BEGIN SET @cMensaje=N'Indique los productos y cantidades que desea transferir.';RETURN;END;
 IF EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad') X
  WHERE X.productoId IS NULL OR X.cantidad IS NULL OR X.cantidad<=0)
 OR EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId') X GROUP BY X.productoId HAVING COUNT(*)>1)
 BEGIN SET @cMensaje=N'Corrija las cantidades o los productos repetidos.';RETURN;END;
 SET @DetalleHash=HASHBYTES('SHA2_256',CONVERT(VARBINARY(MAX),@cDetalleJson));
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenOrigenId AND uot_id=@UotOrigen AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1)
 OR NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenDestinoId AND uot_id=@UotDestino AND estado=1 AND fecha_hasta IS NULL AND permite_entrada=1)
 BEGIN SET @cMensaje=N'Alguno de los almacenes no permite esta transferencia.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @nTransferenciaId=transferencia_almacen_id FROM logistica.TransferenciaAlmacen WITH(UPDLOCK,HOLDLOCK) WHERE clave_idempotencia=@gClaveIdempotencia;
  IF @nTransferenciaId IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM logistica.TransferenciaAlmacen WHERE transferencia_almacen_id=@nTransferenciaId AND almacen_origen_id=@nAlmacenOrigenId AND almacen_destino_id=@nAlmacenDestinoId
      AND detalle_sha256=@DetalleHash) THROW 51003,N'IDEMPOTENCIA',1;
   COMMIT;SET @bResultado=1;SET @cMensaje=N'La transferencia ya fue registrada.';RETURN;END;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad') D
   LEFT JOIN logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK) ON S.almacen_id=@nAlmacenOrigenId AND S.producto_id=D.productoId
   WHERE ISNULL(S.stock_disponible,0)<D.cantidad) THROW 51001,N'INSUFICIENTE',1;
  EXEC logistica.PA_MovimientoInventario_Ins_Registrar @nUsuarioId=@nUsuarioId,@nUotId=@UotOrigen,
   @nAlmacenId=@nAlmacenOrigenId,@cTipo='TRANSFERENCIA',@cNaturaleza='S',
   @gClaveIdempotencia=@ClaveSalida,@cDetalleJson=@cDetalleJson,@cObservacion=@cObservacion,
   @nMovimientoId=@MovS OUTPUT,@bResultado=@Ok OUTPUT,@cMensaje=@Msg OUTPUT;
  IF @Ok<>1 OR @MovS IS NULL THROW 51002,N'MOVIMIENTO_NO_COMPLETADO',1;
  EXEC logistica.PA_MovimientoInventario_Ins_Registrar @nUsuarioId=@nUsuarioId,@nUotId=@UotDestino,
   @nAlmacenId=@nAlmacenDestinoId,@cTipo='TRANSFERENCIA',@cNaturaleza='E',
   @gClaveIdempotencia=@ClaveEntrada,@cDetalleJson=@cDetalleJson,@cObservacion=@cObservacion,
   @nMovimientoId=@MovE OUTPUT,@bResultado=@Ok OUTPUT,@cMensaje=@Msg OUTPUT;
  IF @Ok<>1 OR @MovE IS NULL THROW 51002,N'MOVIMIENTO_NO_COMPLETADO',1;
  /* Los movimientos son inmutables; TransferenciaAlmacen conserva el vínculo entre ambos. */
  INSERT logistica.TransferenciaAlmacen(almacen_origen_id,almacen_destino_id,uot_origen_id,uot_destino_id,movimiento_salida_id,movimiento_entrada_id,clave_idempotencia,detalle_sha256,usuario_id)
  VALUES(@nAlmacenOrigenId,@nAlmacenDestinoId,@UotOrigen,@UotDestino,@MovS,@MovE,@gClaveIdempotencia,@DetalleHash,@nUsuarioId);
  SET @nTransferenciaId=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT;SET @bResultado=1;SET @cMensaje=N'Transferencia registrada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;SET @nTransferenciaId=NULL;
  SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%IDEMPOTENCIA%' THEN N'La solicitud ya fue utilizada para otra operación.'
   WHEN ERROR_MESSAGE() LIKE '%INSUFICIENTE%' THEN N'No hay existencias disponibles suficientes para transferir.'
   ELSE N'No se pudo completar la transferencia.' END;
 END CATCH;
END;
GO
