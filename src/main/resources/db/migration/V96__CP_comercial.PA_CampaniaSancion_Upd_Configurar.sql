IF OBJECT_ID(N'[comercial].[PA_CampaniaSancion_Upd_Configurar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaSancion_Upd_Configurar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaSancion_Upd_Configurar
' Descripción            : Actualiza campania sancion para configurar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaSancion_Upd_Configurar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSancion_Upd_Configurar_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 THROW 52081,N'Solicitud inválida.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52086,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_CONFIGURAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_CONFIGURAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSancion_Upd_Configurar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
  BEGIN TRANSACTION;
  DECLARE @recursoBloqueo NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recursoBloqueo,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52084,N'Otra operación está modificando las sanciones.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52085,N'La clave de solicitud fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Operación realizada previamente.',
       @cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  DECLARE @sancion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.sancionId')),
    @descuento DECIMAL(14,4)=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.descuentoKg')),
    @tarifa BIGINT;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp
     AND estado_proceso IN('PLANIFICACION','ACTIVA')) THROW 52091,N'La campaña no permite editar sanciones.',1;
  IF @descuento IS NULL OR @descuento<=0 OR NOT EXISTS(SELECT 1 FROM comercial.CatalogoSancionVenta WHERE sancion_venta_id=@sancion AND activo=1)
    THROW 52092,N'Seleccione una sanción activa y un descuento positivo por kilogramo.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1)
    THROW 52093,N'Configure primero los precios de los calibres.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1 AND precio_kg<=@descuento)
    THROW 52094,N'El descuento debe ser menor al precio de todos los calibres de la campaña.',1;
  SELECT @tarifa=campania_sancion_tarifa_id FROM comercial.CampaniaSancionTarifa WITH(UPDLOCK,HOLDLOCK)
    WHERE campania_venta_id=@camp AND sancion_venta_id=@sancion;
  IF @tarifa IS NOT NULL AND EXISTS(SELECT 1 FROM comercial.CampaniaSocioSancion WHERE campania_sancion_tarifa_id=@tarifa AND activo=1)
    THROW 52095,N'No puede cambiar la sanción: ya está asignada a socios.',1;
  IF @tarifa IS NULL
  BEGIN
    INSERT comercial.CampaniaSancionTarifa(campania_venta_id,sancion_venta_id,descuento_precio_kg,usuario_registro_id)
      VALUES(@camp,@sancion,@descuento,@usuario);
    SET @tarifa=SCOPE_IDENTITY();
  END
  ELSE UPDATE comercial.CampaniaSancionTarifa SET descuento_precio_kg=@descuento,activo=1,
    usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME() WHERE campania_sancion_tarifa_id=@tarifa;
  SET @cDatos=(SELECT @tarifa tarifaId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSancion_Upd_Configurar',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Operación completada.',@cCodigoRespuesta='SANCION_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='SANCION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52080 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo completar la operación de sanciones.' END;
 END CATCH;
END;
GO
