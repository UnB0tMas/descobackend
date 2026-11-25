IF OBJECT_ID(N'[comercial].[PA_CampaniaDescuentoJaba_Upd_Configurar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaDescuentoJaba_Upd_Configurar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaDescuentoJaba_Upd_Configurar
' Descripción            : Actualiza campania descuento jaba para configurar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaDescuentoJaba_Upd_Configurar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo guardar el descuento.',@cCodigoRespuesta='DESCUENTO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @valor DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT;
 BEGIN TRY
  IF @valor IS NOT NULL AND (@valor<0 OR @valor>9.999) THROW 52021,N'El descuento debe estar entre 0 y 9.999 kg.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52022,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1 THROW 52023,N'Sin permiso para editar campañas.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52024,N'La campaña está siendo modificada.',1;
  -- El nuevo descuento también actualiza los pesajes existentes con auditoría.
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado_proceso IN('PLANIFICACION','ACTIVA'))
    THROW 52026,N'La campaña no admite modificaciones.',1;
  UPDATE comercial.CampaniaControlE4 SET tara_kg=COALESCE(@valor,0),version=version+1,
    usuario_id=@usuario,actualizado_en=SYSUTCDATETIME() WHERE campania_venta_id=@camp;
  IF @@ROWCOUNT<>1 THROW 52076,N'Configure el cupo de jabas antes de cambiar la tara.',1;
  -- TR_CampaniaControlE4_TaraVenta sincroniza el campo técnico y recalcula los pesajes auditables.
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaVenta',@camp,'CONFIGURAR_DESCUENTO',(SELECT @valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @camp campaniaId,@valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  SELECT @bResultado=1,@cMensaje=N'Descuento actualizado.',@cCodigoRespuesta='DESCUENTO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='DESCUENTO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo guardar el descuento.' END;
 END CATCH;
END;
GO
