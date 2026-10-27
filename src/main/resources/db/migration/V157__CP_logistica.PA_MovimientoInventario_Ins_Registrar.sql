IF OBJECT_ID(N'[logistica].[PA_MovimientoInventario_Ins_Registrar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_MovimientoInventario_Ins_Registrar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_MovimientoInventario_Ins_Registrar
' Descripción             : Registra un movimiento en el inventario.
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
        @nMovimientoId BIGINT,
        @bResultado BIT,
        @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_MovimientoInventario_Ins_Registrar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nAlmacenId = 0,
        @cTipo = '',
        @cNaturaleza = '',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @cDetalleJson = N'',
        @nProveedorPersonaId = 0,
        @nProveedorEmpresaId = 0,
        @cDocumento = N'',
        @cObservacion = N'',
        @nMovimientoId = @nMovimientoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nMovimientoId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_MovimientoInventario_Ins_Registrar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@cTipo VARCHAR(25),@cNaturaleza CHAR(1),@gClaveIdempotencia UNIQUEIDENTIFIER,
 @cDetalleJson NVARCHAR(MAX),@nProveedorPersonaId BIGINT=NULL,@nProveedorEmpresaId BIGINT=NULL,@cDocumento NVARCHAR(120)=NULL,@cObservacion NVARCHAR(500)=NULL,
 @nMovimientoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; SET @nMovimientoId=NULL; SET @bResultado=0; SET @cMensaje=N'No se pudo registrar el movimiento de inventario.';
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'ALMACENES_MOVIMIENTO')=0 BEGIN SET @cMensaje=N'No tiene permiso para registrar movimientos de inventario.'; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT AU WHERE AU.almacen_id=@nAlmacenId AND AU.uot_id=@nUotId AND AU.estado=1 AND AU.fecha_hasta IS NULL AND ((@cNaturaleza='E' AND AU.permite_entrada=1) OR (@cNaturaleza='S' AND AU.permite_salida=1))) BEGIN SET @cMensaje=N'La UOT no puede operar sobre el almacén seleccionado.'; RETURN; END;
 SET @cTipo=UPPER(NULLIF(LTRIM(RTRIM(@cTipo)),'')); SET @cNaturaleza=UPPER(@cNaturaleza);
 IF @cNaturaleza NOT IN('E','S') OR @cTipo NOT IN('COMPRA','DONACION','DEVOLUCION','VENTA','CONSUMO','TRANSFERENCIA','AJUSTE','MERMA','OTRO') BEGIN SET @cMensaje=N'El tipo de movimiento no es válido.'; RETURN; END;
 IF @gClaveIdempotencia IS NULL BEGIN SET @cMensaje=N'La clave de idempotencia es obligatoria.'; RETURN; END;
 SELECT @nMovimientoId=movimiento_inventario_id FROM logistica.MovimientoInventario WHERE clave_idempotencia=@gClaveIdempotencia;
 IF @nMovimientoId IS NOT NULL BEGIN SET @bResultado=1; SET @cMensaje=N'El movimiento ya fue registrado correctamente.'; RETURN; END;
 IF ISJSON(@cDetalleJson)<>1 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson)) BEGIN SET @cMensaje=N'El movimiento debe incluir al menos un producto.'; RETURN; END;
 IF EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad') D WHERE D.productoId IS NULL OR D.cantidad IS NULL OR D.cantidad<=0) BEGIN SET @cMensaje=N'El detalle del movimiento contiene datos inválidos.'; RETURN; END;
 IF EXISTS(
     SELECT 1
     FROM OPENJSON(@cDetalleJson)
     WITH(fechaVencimiento DATE '$.fechaVencimiento') D
     WHERE D.fechaVencimiento IS NOT NULL
       AND D.fechaVencimiento < CONVERT(date, SYSDATETIME())
 ) BEGIN SET @cMensaje=N'La fecha de vencimiento no puede ser anterior a hoy.'; RETURN; END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; BEGIN TRAN;
  IF @cNaturaleza='S' AND EXISTS(SELECT 1 FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad') D LEFT JOIN logistica.AlmacenProductoStock S WITH(UPDLOCK,HOLDLOCK) ON S.almacen_id=@nAlmacenId AND S.producto_id=D.productoId WHERE ISNULL(S.stock_disponible,0)<D.cantidad) THROW 51050,N'STOCK_INSUFICIENTE',1;
  INSERT logistica.MovimientoInventario(almacen_id,uot_id,tipo_movimiento,naturaleza,proveedor_persona_id,proveedor_empresa_id,documento_referencia,clave_idempotencia,usuario_id,observacion,estado)
  VALUES(@nAlmacenId,@nUotId,UPPER(@cTipo),UPPER(@cNaturaleza),@nProveedorPersonaId,@nProveedorEmpresaId,@cDocumento,@gClaveIdempotencia,@nUsuarioId,@cObservacion,1);
  SET @nMovimientoId=SCOPE_IDENTITY();
  INSERT logistica.DetalleMovimientoInventario(movimiento_inventario_id,producto_id,cantidad,costo_unitario,moneda,lote,fecha_vencimiento)
  SELECT @nMovimientoId,productoId,cantidad,costoUnitario,UPPER(moneda),lote,fechaVencimiento
  FROM OPENJSON(@cDetalleJson) WITH(productoId BIGINT '$.productoId',cantidad DECIMAL(19,3) '$.cantidad',costoUnitario DECIMAL(19,4) '$.costoUnitario',moneda CHAR(3) '$.moneda',lote VARCHAR(80) '$.lote',fechaVencimiento DATE '$.fechaVencimiento');

  MERGE logistica.AlmacenProductoStock WITH(HOLDLOCK) AS T
  USING(SELECT producto_id,SUM(cantidad) cantidad FROM logistica.DetalleMovimientoInventario WHERE movimiento_inventario_id=@nMovimientoId GROUP BY producto_id) S
  ON T.almacen_id=@nAlmacenId AND T.producto_id=S.producto_id
  WHEN NOT MATCHED AND @cNaturaleza='E' THEN INSERT(almacen_id,producto_id,stock_actual,stock_reservado,stock_minimo,fecha_actualizacion) VALUES(@nAlmacenId,S.producto_id,S.cantidad,0,0,SYSUTCDATETIME())
  WHEN MATCHED THEN UPDATE SET stock_actual=T.stock_actual+CASE WHEN @cNaturaleza='E' THEN S.cantidad ELSE -S.cantidad END,fecha_actualizacion=SYSUTCDATETIME();

  IF EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WHERE almacen_id=@nAlmacenId AND (stock_actual<0 OR stock_reservado>stock_actual)) THROW 51050,N'STOCK_INSUFICIENTE',1;
  COMMIT; SET @bResultado=1; SET @cMensaje=N'Movimiento de inventario registrado correctamente.';
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK; SET @nMovimientoId=NULL;
  SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%STOCK_INSUFICIENTE%' THEN N'No hay stock suficiente para completar el movimiento.' ELSE N'No se pudo registrar el movimiento de inventario.' END;
 END CATCH;
END;
GO
