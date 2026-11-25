IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaRecepcion_Upd_Confirmar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaRecepcion_Upd_Confirmar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaRecepcion_Upd_Confirmar
' Descripción            : Gestiona campania jaba recepcion: confirmar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaRecepcion_Upd_Confirmar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo confirmar la recepción.',
   @cCodigoRespuesta='RECEPCION_CONFIRMACION_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@plan BIGINT,@asignadas INT,@registradas INT,@estado VARCHAR(20),@confirmada BIT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  IF @camp IS NULL OR @part IS NULL OR @clave IS NULL
    THROW 52030,N'Indique la campaña y el socio.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52031,N'La campaña no está disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
    THROW 52032,N'No tiene permiso para confirmar la recepción.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'RECEPCION_CONFIRMAR|',@camp,'|',@part));
  BEGIN TRANSACTION;
  DECLARE @recurso NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52033,N'Otra operación está procesando las jabas.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52034,N'Esta solicitud ya se utilizó para otra operación.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Confirmación registrada anteriormente.',
      @cCodigoRespuesta='RECEPCION_CONFIRMADA_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
      WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
      AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 52035,N'La recepción solo puede confirmarse durante la campaña vigente.',1;
  SELECT @plan=J.campania_jaba_plan_id,@asignadas=J.cantidad,@estado=J.estado,
    @confirmada=J.recepcion_confirmada
    FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@part
      AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1;
  IF @plan IS NULL OR @asignadas<1 OR @estado NOT IN('ENTREGADA','DEVUELTA') OR ISNULL(@confirmada,0)=1
    THROW 52036,N'La recepción ya fue confirmada o no está disponible.',1;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion R WITH(UPDLOCK,HOLDLOCK)
    WHERE R.campania_jaba_plan_id=@plan;
  IF @registradas<>@asignadas
    THROW 52037,N'Debe registrar todas las jabas antes de confirmar la entrega.',1;
  UPDATE comercial.CampaniaJabaPlan SET recepcion_confirmada=1,
    fecha_confirmacion_recepcion=SYSUTCDATETIME(),usuario_confirmacion_recepcion_id=@usuario,
    estado='DEVUELTA',fecha_devolucion=COALESCE(fecha_devolucion,SYSUTCDATETIME()),
    usuario_modifica_id=@usuario,version=version+1
    WHERE campania_jaba_plan_id=@plan AND recepcion_confirmada=0;
  IF @@ROWCOUNT<>1 THROW 52036,N'La recepción cambió. Actualice el detalle.',1;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaPlan',@plan,'CONFIRMAR_RECEPCION',
      (SELECT @part participacionId,@asignadas jabasRegistradas,
       (SELECT COALESCE(SUM(R.peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=@plan) pesoBrutoKg,
       (SELECT COALESCE(SUM(R.peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=@plan) pesoNetoKg
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @part participacionId,@asignadas asignadas,@registradas registradas,
      'DEVUELTA' estado,CAST(1 AS BIT) recepcionConfirmada FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'RECEPCION_CONFIRMAR',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Entrega confirmada.',@cCodigoRespuesta='RECEPCION_CONFIRMADA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_CONFIRMACION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52000 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52000 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499
       THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo confirmar la recepción.' END;
 END CATCH;
END;
GO
