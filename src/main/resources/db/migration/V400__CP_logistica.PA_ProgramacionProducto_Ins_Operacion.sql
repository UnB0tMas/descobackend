IF OBJECT_ID(N'[logistica].[PA_ProgramacionProducto_Ins_Operacion]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProgramacionProducto_Ins_Operacion];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProgramacionProducto_Ins_Operacion
' Descripción             : Registra aprobación, entrega, devolución, consumo o cierre de una solicitud.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de ciclo de vida de solicitudes técnicas.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nEventoId BIGINT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_ProgramacionProducto_Ins_Operacion]
        @nUsuarioId = 0,
        @nProgramacionId = 0,
        @cOperacion = '',
        @nCantidad = 0,
        @cObservacion = N'',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nEventoId = @nEventoId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nEventoId, @bResultado, @cMensaje;
*******************************************************************************************************/
CREATE PROCEDURE logistica.PA_ProgramacionProducto_Ins_Operacion
 @nUsuarioId BIGINT,@nProgramacionId BIGINT,@cOperacion VARCHAR(20),
 @nCantidad DECIMAL(19,3)=NULL,@cObservacion NVARCHAR(300)=NULL,
 @gClaveIdempotencia UNIQUEIDENTIFIER,
 @nEventoId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @nEventoId=NULL,@bResultado=0,@cMensaje=N'No se pudo procesar el recurso.';
 SET @cOperacion=UPPER(NULLIF(LTRIM(RTRIM(@cOperacion)),''));
 IF @cOperacion NOT IN('APROBAR','RECHAZAR','ENTREGAR','DEVOLVER','CONSUMIR','CERRAR','CANCELAR') OR @gClaveIdempotencia IS NULL
 BEGIN SET @cMensaje=N'La operación solicitada no es válida.';RETURN;END;
 DECLARE @Uot BIGINT,@Almacen BIGINT,@Producto BIGINT,@Estado VARCHAR(20),@Programada DECIMAL(19,3),
  @Entregada DECIMAL(19,3),@Devuelta DECIMAL(19,3),@Consumida DECIMAL(19,3),
  @Mov BIGINT=NULL,@Ok BIT,@Msg NVARCHAR(300),@Detalle NVARCHAR(MAX),@Permiso VARCHAR(60),@Disponible DECIMAL(19,3);
 SELECT @Uot=uot_id FROM logistica.ProgramacionProducto WHERE programacion_producto_id=@nProgramacionId;
 IF @Uot IS NULL BEGIN SET @cMensaje=N'La solicitud no se encuentra disponible.';RETURN;END;
 SET @Permiso=CASE WHEN @cOperacion IN('APROBAR','RECHAZAR','CANCELAR','CERRAR') THEN 'RECURSOS_EDITAR'
                 ELSE 'ALMACENES_MOVIMIENTO' END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@Uot,@Permiso)=0
 BEGIN SET @cMensaje=N'No tiene autorización para realizar esta operación.';RETURN;END;
 IF (@cOperacion IN('ENTREGAR','DEVOLVER','CONSUMIR') AND (@nCantidad IS NULL OR @nCantidad<=0))
 OR (@cOperacion NOT IN('ENTREGAR','DEVOLVER','CONSUMIR') AND @nCantidad IS NOT NULL)
 BEGIN SET @cMensaje=N'Indique una cantidad válida para la operación.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @nEventoId=programacion_producto_evento_id
   FROM logistica.ProgramacionProductoEvento WITH(UPDLOCK,HOLDLOCK) WHERE clave_idempotencia=@gClaveIdempotencia;
  IF @nEventoId IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM logistica.ProgramacionProductoEvento WHERE programacion_producto_evento_id=@nEventoId
      AND programacion_producto_id=@nProgramacionId AND tipo_evento=@cOperacion
      AND (@nCantidad IS NULL AND cantidad IS NULL OR cantidad=@nCantidad)
      AND (observacion=@cObservacion OR (observacion IS NULL AND @cObservacion IS NULL))) THROW 51005,N'IDEMPOTENCIA',1;
   COMMIT;SET @bResultado=1;SET @cMensaje=N'La operación ya fue procesada.';RETURN;
  END;
  SELECT @Uot=uot_id,@Almacen=almacen_id,@Producto=producto_id,@Estado=estado_proceso,
   @Programada=cantidad_programada,@Entregada=cantidad_entregada,@Devuelta=cantidad_devuelta,@Consumida=cantidad_consumida
  FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE programacion_producto_id=@nProgramacionId;
  IF @Estado IS NULL THROW 51001,N'NO_DISPONIBLE',1;
  IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@Almacen AND uot_propietaria_id=@Uot AND estado=1) THROW 51001,N'ALMACEN',1;
  IF EXISTS(SELECT 1 FROM logistica.ProductoUOTPolitica WHERE uot_id=@Uot AND producto_id=@Producto AND estado=0) THROW 51001,N'POLITICA',1;
  IF @cOperacion IN('APROBAR','RECHAZAR','CANCELAR') AND @Estado NOT IN('PENDIENTE','APROBADA') THROW 51001,N'ESTADO',1;
  IF @cOperacion IN('ENTREGAR','DEVOLVER','CONSUMIR','CERRAR') AND @Estado NOT IN('APROBADA','ENTREGADA','FINALIZADA') THROW 51001,N'ESTADO',1;
  IF @cOperacion='APROBAR'
  BEGIN
   IF @Estado<>'PENDIENTE' THROW 51001,N'ESTADO',1;
   UPDATE logistica.AlmacenProductoStock WITH(UPDLOCK,SERIALIZABLE)
    SET stock_reservado=stock_reservado+@Programada,fecha_actualizacion=SYSUTCDATETIME()
   WHERE almacen_id=@Almacen AND producto_id=@Producto AND stock_disponible>=@Programada;
   IF @@ROWCOUNT<>1 THROW 51001,N'INSUFICIENTE',1;
   UPDATE logistica.ProgramacionProducto SET estado_proceso='APROBADA',usuario_aprobador_id=@nUsuarioId,
     fecha_aprobacion=SYSUTCDATETIME() WHERE programacion_producto_id=@nProgramacionId;
  END;
  IF @cOperacion IN('RECHAZAR','CANCELAR')
  BEGIN
   IF @cOperacion='RECHAZAR' AND @Estado<>'PENDIENTE' THROW 51001,N'ESTADO',1;
   IF @Estado='APROBADA'
   BEGIN
    UPDATE logistica.AlmacenProductoStock WITH(UPDLOCK)
    SET stock_reservado=stock_reservado-@Programada,fecha_actualizacion=SYSUTCDATETIME()
    WHERE almacen_id=@Almacen AND producto_id=@Producto AND stock_reservado>=@Programada;
    IF @@ROWCOUNT<>1 THROW 51001,N'RESERVA',1;
   END;
   UPDATE logistica.ProgramacionProducto SET estado_proceso=CASE WHEN @cOperacion='RECHAZAR' THEN 'RECHAZADA' ELSE 'CANCELADA' END,
    motivo_cierre=@cObservacion WHERE programacion_producto_id=@nProgramacionId;
  END;
  IF @cOperacion='ENTREGAR'
  BEGIN
   IF @Estado<>'APROBADA' OR @nCantidad<>@Programada THROW 51001,N'ESTADO',1;
   UPDATE logistica.AlmacenProductoStock WITH(UPDLOCK)
     SET stock_reservado=stock_reservado-@Programada,fecha_actualizacion=SYSUTCDATETIME()
   WHERE almacen_id=@Almacen AND producto_id=@Producto AND stock_reservado>=@Programada;
   IF @@ROWCOUNT<>1 THROW 51001,N'RESERVA',1;
   SET @Detalle=(SELECT @Producto AS productoId,@nCantidad AS cantidad FOR JSON PATH);
   EXEC logistica.PA_MovimientoInventario_Ins_Registrar
     @nUsuarioId=@nUsuarioId,@nUotId=@Uot,@nAlmacenId=@Almacen,
     @cTipo='USO_TECNICO',@cNaturaleza='S',@gClaveIdempotencia=@gClaveIdempotencia,
     @cDetalleJson=@Detalle,@cDocumento=NULL,@cObservacion=@cObservacion,
     @nMovimientoId=@Mov OUTPUT,@bResultado=@Ok OUTPUT,@cMensaje=@Msg OUTPUT;
   IF @Ok<>1 OR @Mov IS NULL THROW 51001,N'MOVIMIENTO',1;
   UPDATE logistica.ProgramacionProducto SET cantidad_entregada=@Programada,estado_proceso='ENTREGADA' WHERE programacion_producto_id=@nProgramacionId;
  END;
  IF @cOperacion='DEVOLVER'
  BEGIN
   IF @Estado<>'ENTREGADA' OR @nCantidad>@Entregada-@Devuelta-@Consumida THROW 51001,N'EXCESO',1;
   SET @Detalle=(SELECT @Producto AS productoId,@nCantidad AS cantidad FOR JSON PATH);
   EXEC logistica.PA_MovimientoInventario_Ins_Registrar
     @nUsuarioId=@nUsuarioId,@nUotId=@Uot,@nAlmacenId=@Almacen,
     @cTipo='DEVOLUCION',@cNaturaleza='E',@gClaveIdempotencia=@gClaveIdempotencia,
     @cDetalleJson=@Detalle,@cDocumento=NULL,@cObservacion=@cObservacion,
     @nMovimientoId=@Mov OUTPUT,@bResultado=@Ok OUTPUT,@cMensaje=@Msg OUTPUT;
   IF @Ok<>1 OR @Mov IS NULL THROW 51001,N'MOVIMIENTO',1;
   UPDATE logistica.ProgramacionProducto SET cantidad_devuelta=cantidad_devuelta+@nCantidad,
     estado_proceso=CASE WHEN @Entregada-@Devuelta-@Consumida=@nCantidad THEN 'FINALIZADA' ELSE 'ENTREGADA' END
    WHERE programacion_producto_id=@nProgramacionId;
  END;
  IF @cOperacion='CONSUMIR'
  BEGIN
   IF @Estado<>'ENTREGADA' OR @nCantidad>@Entregada-@Devuelta-@Consumida THROW 51001,N'EXCESO',1;
   /* La salida de almacén ya se registró al entregar; no descontar dos veces. */
   UPDATE logistica.ProgramacionProducto SET cantidad_consumida=cantidad_consumida+@nCantidad,
     estado_proceso=CASE WHEN @Entregada-@Devuelta-@Consumida=@nCantidad THEN 'FINALIZADA' ELSE 'ENTREGADA' END
    WHERE programacion_producto_id=@nProgramacionId;
  END;
  IF @cOperacion='CERRAR'
  BEGIN
   IF @Estado NOT IN('ENTREGADA','FINALIZADA') OR @Entregada<>@Devuelta+@Consumida THROW 51001,N'PENDIENTE',1;
   UPDATE logistica.ProgramacionProducto SET estado_proceso='FINALIZADA',motivo_cierre=@cObservacion WHERE programacion_producto_id=@nProgramacionId;
  END;
  INSERT logistica.ProgramacionProductoEvento(programacion_producto_id,tipo_evento,cantidad,movimiento_inventario_id,usuario_id,clave_idempotencia,observacion)
   VALUES(@nProgramacionId,@cOperacion,@nCantidad,@Mov,@nUsuarioId,@gClaveIdempotencia,@cObservacion);
  SET @nEventoId=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT;SET @bResultado=1;SET @cMensaje=N'Operación registrada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;SET @nEventoId=NULL;
  SET @cMensaje=CASE WHEN ERROR_MESSAGE() LIKE '%INSUFICIENTE%' THEN N'El producto no tiene stock disponible suficiente.'
   WHEN ERROR_MESSAGE() LIKE '%EXCESO%' THEN N'La cantidad supera lo pendiente de devolver o consumir.'
   WHEN ERROR_MESSAGE() LIKE '%IDEMPOTENCIA%' THEN N'La solicitud ya fue utilizada para otra operación.'
   WHEN ERROR_MESSAGE() LIKE '%PENDIENTE%' THEN N'Debe regularizar todas las cantidades antes de finalizar.'
   WHEN ERROR_MESSAGE() LIKE '%ESTADO%' THEN N'La solicitud no permite esta operación en su estado actual.'
   ELSE N'No se pudo procesar el recurso.' END;
 END CATCH;
END;
GO
