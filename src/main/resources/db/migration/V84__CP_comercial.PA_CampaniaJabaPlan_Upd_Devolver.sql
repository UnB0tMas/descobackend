IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaPlan_Upd_Devolver]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaPlan_Upd_Devolver];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaPlan_Upd_Devolver
' Descripción            : Actualiza campania jaba plan para devolver.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Devolver
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo confirmar la devolución.',@cCodigoRespuesta='JABAS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @participacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
  @id BIGINT,@cantidad INT,@pendiente INT,@objetivo INT,@maxRegistrada INT=0,@comentario NVARCHAR(500);
 BEGIN TRY
  IF @camp IS NULL OR @participacion IS NULL OR @clave IS NULL
   THROW 51460,N'Indique campaña y participante.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C
   WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51461,N'La campaña no permite devolver jabas.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
   THROW 51462,N'Sin permiso para confirmar devoluciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'DEVOLVER_JABAS|',@camp,'|',@participacion));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51463,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51464,N'La clave corresponde a otra solicitud.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Devolución procesada anteriormente.',
    @cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
    AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
   THROW 51465,N'La devolución solo se confirma durante la campaña.',1;
  SELECT @id=J.campania_jaba_plan_id,@cantidad=J.cantidad,
   @pendiente=J.cantidad_ajuste_pendiente,@comentario=J.comentario_ajuste_pendiente
   FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@participacion
    AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1
    AND J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente<0;
  IF @id IS NULL THROW 51466,N'No hay jabas pendientes de devolución.',1;
  SET @objetivo=@cantidad+@pendiente;
  SELECT @maxRegistrada=COALESCE(MAX(R.numero_jaba),0)
    FROM comercial.CampaniaJabaRecepcion R WITH(UPDLOCK,HOLDLOCK)
    WHERE R.campania_jaba_plan_id=@id;
  IF @objetivo<@maxRegistrada
    THROW 51467,N'No es posible devolver jabas ya registradas en venta.',1;
  IF @objetivo=0
    UPDATE comercial.CampaniaJabaPlan SET cantidad=0,estado='DEVUELTA',fecha_devolucion=SYSUTCDATETIME(),
      cantidad_ajuste_pendiente=0,comentario_ajuste_pendiente=NULL,
      version=version+1,usuario_modifica_id=@usuario WHERE campania_jaba_plan_id=@id;
  ELSE
    UPDATE comercial.CampaniaJabaPlan SET cantidad=@objetivo,
      cantidad_ajuste_pendiente=0,comentario_ajuste_pendiente=NULL,
      version=version+1,usuario_modifica_id=@usuario WHERE campania_jaba_plan_id=@id;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaJabaPlan',@id,'DEVOLVER_JABAS',
    (SELECT @participacion participacionId,-@pendiente cantidadDevuelta,@cantidad cantidadAnterior,
      @objetivo cantidadRestante,@comentario comentario FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId,@participacion participacionId,@objetivo cantidad,
    CASE WHEN @objetivo=0 THEN 'DEVUELTA' ELSE 'ENTREGADA' END estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
   VALUES(@usuario,@clave,'DEVOLVER_JABAS_PLAN',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Devolución registrada.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='JABAS_PLAN_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo confirmar la devolución.' END;
 END CATCH;
END;
GO
