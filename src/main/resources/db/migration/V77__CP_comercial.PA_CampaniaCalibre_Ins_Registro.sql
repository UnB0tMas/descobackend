IF OBJECT_ID(N'[comercial].[PA_CampaniaCalibre_Ins_Registro]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaCalibre_Ins_Registro];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaCalibre_Ins_Registro
' Descripción            : Registra la información de campania calibre.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaCalibre_Ins_Registro
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo agregar el calibre.',@cCodigoRespuesta='CALIBRE_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadPaltaId')),
  @calibre VARCHAR(12)=UPPER(JSON_VALUE(@cJson,'$.datos.calibre')),
  @desde INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.gramosDesde')),
  @hasta INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.gramosHasta')),
  @precio DECIMAL(14,4)=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioKg')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT,@id BIGINT;
 BEGIN TRY
  IF @calibre NOT IN('PRIMERA','SEGUNDA','DESCARTE') OR @desde IS NULL OR @desde<0
   OR (@hasta IS NOT NULL AND @hasta<@desde) OR @precio IS NULL OR @precio<=0 OR @variedad IS NULL
   THROW 52031,N'Indique variedad, calibre, rango en gramos y precio positivo.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52032,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PRECIOS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1 THROW 52033,N'Sin permiso para registrar calibres.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52034,N'La campaña está siendo modificada.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA'))
     THROW 52035,N'La campaña ya no permite registrar calibres.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.VariedadPalta WHERE variedad_palta_id=@variedad AND estado=1)
     THROW 52036,N'La variedad no existe.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre X WITH(UPDLOCK,HOLDLOCK)
   WHERE X.campania_venta_id=@camp AND X.variedad_palta_id=@variedad
    AND (X.calibre=@calibre OR (@desde<=COALESCE(X.gramos_hasta,2147483647)
      AND X.gramos_desde<=COALESCE(@hasta,2147483647))))
    THROW 52037,N'Existe un calibre duplicado o con rango de gramos superpuesto.',1;
  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id)
   VALUES(@camp,@variedad,@calibre,@desde,@hasta,@precio,@usuario);
  SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
   VALUES(@id,1,@precio,@usuario);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaCalibre',@id,'CREAR_CALIBRE',
      (SELECT @variedad variedadPaltaId,@calibre calibre,@desde gramosDesde,@hasta gramosHasta,@precio precioKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @id calibreId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Calibre agregado.',@cCodigoRespuesta='CALIBRE_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CALIBRE_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo agregar el calibre.' END;
 END CATCH;
END;
GO
