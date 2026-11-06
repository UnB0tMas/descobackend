IF OBJECT_ID(N'[logistica].[PA_ProgramacionProducto_Ins_Solicitar]', N'P') IS NOT NULL
    DROP PROCEDURE [logistica].[PA_ProgramacionProducto_Ins_Solicitar];
GO

/******************************************************************************************************
' Nombre del PA           : logistica.PA_ProgramacionProducto_Ins_Solicitar
' Descripción             : Solicita un producto del catálogo para utilización técnica.
'
' Autor / Fecha           : JJFL / 11.10.2026
' Aplicativo / Módulo     : DESCO / Logística
'
' ----------------------------------------------------------------------------------------------------------------
' Historial de cambios:
' Fecha        Autor  Descripción
' 11.10.2026   JJFL   Creación de solicitudes técnicas por UOT.
' ----------------------------------------------------------------------------------------------------------------
' Ejemplo de Ejecución:
    -- Referencial: sustituir identificadores y valores por datos válidos.
    DECLARE @nProgramacionId BIGINT,
            @bResultado BIT,
            @cMensaje NVARCHAR(300);
    EXEC [logistica].[PA_ProgramacionProducto_Ins_Solicitar]
        @nUsuarioId = 0,
        @nUotId = 0,
        @nAlmacenId = 0,
        @nProductoId = 0,
        @nEmpleadoId = 0,
        @nCantidad = 0,
        @cActividad = N'',
        @cLugar = N'',
        @dInicio = '2026-10-11T00:00:00',
        @dFin = '2026-10-11T00:00:00',
        @nArchivoId = 0,
        @cObservacion = N'',
        @gClaveIdempotencia = '00000000-0000-0000-0000-000000000001',
        @nProgramacionId = @nProgramacionId OUTPUT,
        @bResultado = @bResultado OUTPUT,
        @cMensaje = @cMensaje OUTPUT;
    SELECT @nProgramacionId, @bResultado, @cMensaje;
*******************************************************************************************************/
IF OBJECT_ID(N'logistica.PA_ProgramacionProducto_Ins_Solicitar', N'P') IS NOT NULL DROP PROCEDURE logistica.PA_ProgramacionProducto_Ins_Solicitar;
GO
CREATE PROCEDURE logistica.PA_ProgramacionProducto_Ins_Solicitar
 @nUsuarioId BIGINT,@nUotId BIGINT,@nAlmacenId BIGINT,@nProductoId BIGINT,@nEmpleadoId BIGINT,
 @nCantidad DECIMAL(19,3),@cActividad NVARCHAR(250),@cLugar NVARCHAR(300),
 @dInicio DATETIME2(0),@dFin DATETIME2(0)=NULL,@nArchivoId BIGINT=NULL,
 @cObservacion NVARCHAR(500)=NULL,@gClaveIdempotencia UNIQUEIDENTIFIER,
 @nProgramacionId BIGINT OUTPUT,@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @nProgramacionId=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la solicitud.';
 SET @cActividad=NULLIF(LTRIM(RTRIM(@cActividad)),N'');
 SET @cLugar=NULLIF(LTRIM(RTRIM(@cLugar)),N'');
 IF @nCantidad IS NULL OR @nCantidad<=0 OR @cActividad IS NULL OR @cLugar IS NULL OR @dInicio IS NULL
  OR (@dFin IS NOT NULL AND @dFin<@dInicio) OR @gClaveIdempotencia IS NULL
 BEGIN SET @cMensaje=N'Complete correctamente los datos de la solicitud.';RETURN;END;
 IF seg.FN_Usuario_TienePermisoUOT(@nUsuarioId,@nUotId,'RECURSOS_CREAR')=0
 BEGIN SET @cMensaje=N'No tiene permiso para solicitar recursos en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Almacen WHERE almacen_id=@nAlmacenId AND uot_propietaria_id=@nUotId AND estado=1)
 BEGIN SET @cMensaje=N'El almacén seleccionado no está disponible en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenUOT WHERE almacen_id=@nAlmacenId AND uot_id=@nUotId
 AND estado=1 AND fecha_hasta IS NULL AND permite_salida=1)
 BEGIN SET @cMensaje=N'El almacén no permite entregar recursos en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM logistica.Producto P JOIN logistica.ProductoUOTPolitica U ON U.producto_id=P.producto_id AND U.uot_id=@nUotId
 WHERE P.producto_id=@nProductoId AND P.estado=1 AND U.estado=1 AND U.permite_uso_interno=1)
 BEGIN SET @cMensaje=N'El producto no está habilitado para uso interno en esta UOT.';RETURN;END;
 IF NOT EXISTS(SELECT 1 FROM org.Empleado E JOIN org.EmpleadoUOT EU ON EU.empleado_id=E.empleado_id
 WHERE E.empleado_id=@nEmpleadoId AND E.estado=1 AND (E.fecha_cese IS NULL OR E.fecha_cese>=CONVERT(DATE,SYSUTCDATETIME())) AND EU.uot_id=@nUotId AND EU.estado=1 AND EU.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
   AND (EU.fecha_hasta IS NULL OR EU.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME())))
 BEGIN SET @cMensaje=N'El técnico no pertenece a esta UOT.';RETURN;END;
 IF @nArchivoId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM archivo.Archivo WHERE archivo_id=@nArchivoId AND uot_id=@nUotId AND estado=1
  AND proveedor_almacenamiento='LOCAL' AND clave_almacenamiento IS NOT NULL)
 BEGIN SET @cMensaje=N'El documento de autorización no está disponible en esta UOT.';RETURN;END;
 BEGIN TRY
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;BEGIN TRAN;
  SELECT @nProgramacionId=programacion_producto_id FROM logistica.ProgramacionProducto WITH(UPDLOCK,HOLDLOCK) WHERE clave_idempotencia=@gClaveIdempotencia;
  IF @nProgramacionId IS NOT NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM logistica.ProgramacionProducto WHERE programacion_producto_id=@nProgramacionId AND uot_id=@nUotId AND almacen_id=@nAlmacenId AND producto_id=@nProductoId AND empleado_id=@nEmpleadoId AND cantidad_programada=@nCantidad AND actividad=@cActividad AND lugar_destino=@cLugar AND fecha_inicio=@dInicio)
      THROW 51001,N'CLAVE_REUTILIZADA',1;
   COMMIT;SET @bResultado=1;SET @cMensaje=N'La solicitud ya fue registrada.';RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM logistica.AlmacenProductoStock WITH(UPDLOCK,HOLDLOCK)
   WHERE almacen_id=@nAlmacenId AND producto_id=@nProductoId AND estado=1)
  BEGIN SET @cMensaje=N'El producto debe estar incorporado y activo en el almacén seleccionado.';THROW 51121,@cMensaje,1;END;
  INSERT logistica.ProgramacionProducto(uot_id,almacen_id,producto_id,empleado_id,cantidad_programada,actividad,lugar_destino,fecha_inicio,fecha_fin,
   observacion,archivo_autorizacion_id,usuario_solicitante_id,clave_idempotencia)
  VALUES(@nUotId,@nAlmacenId,@nProductoId,@nEmpleadoId,@nCantidad,@cActividad,@cLugar,@dInicio,@dFin,@cObservacion,@nArchivoId,@nUsuarioId,@gClaveIdempotencia);
  SET @nProgramacionId=CONVERT(BIGINT,SCOPE_IDENTITY());
  COMMIT;SET @bResultado=1;SET @cMensaje=N'Solicitud registrada correctamente.';
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;SET @nProgramacionId=NULL;
  SET @cMensaje=CASE WHEN ERROR_NUMBER()=51121 THEN ERROR_MESSAGE() WHEN ERROR_MESSAGE() LIKE '%CLAVE_REUTILIZADA%' THEN N'La solicitud ya fue utilizada para otra operación.'
  ELSE N'No se pudo registrar la solicitud.' END;
 END CATCH;
END;
GO
