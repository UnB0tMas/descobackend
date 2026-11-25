IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaPlan_Upd_Entregar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaPlan_Upd_Entregar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaPlan_Upd_Entregar
' Descripción            : Actualiza campania jaba plan para entregar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Entregar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo confirmar la entrega.',@cCodigoRespuesta='JABAS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @participacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
 @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@id BIGINT,@cantidad INT,
 @stock INT,@existentes BIGINT,@entregadas BIGINT,@origen VARCHAR(12),@pendiente INT=0,@estado VARCHAR(20),@entrega INT;
 BEGIN TRY
  IF @camp IS NULL OR @participacion IS NULL OR @clave IS NULL THROW 51450,N'Indique la campaña y el participante.',1;
  SELECT @uot=uot_id,@origen=origen_jabas FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51451,N'La campaña no permite entregar jabas.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
   THROW 51452,N'No tiene permiso para confirmar entregas de jabas.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'ENTREGAR_JABAS|',@camp,'|',@participacion));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51453,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK) WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51454,N'La clave de idempotencia corresponde a otra solicitud.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Entrega procesada anteriormente.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  SELECT @origen=C.origen_jabas FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK) WHERE C.campania_venta_id=@camp AND C.uot_id=@uot;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
    AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 51458,N'La entrega de jabas solo puede confirmarse durante la campaña.',1;
  SELECT @id=J.campania_jaba_plan_id,@cantidad=J.cantidad,
    @pendiente=J.cantidad_ajuste_pendiente,@estado=J.estado
    FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@participacion
     AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1
     AND (J.estado='PENDIENTE_RECOJO' OR (J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente>0));
  IF @id IS NULL THROW 51455,N'El socio no tiene jabas pendientes de recojo.',1;
  SET @entrega=CASE WHEN @estado='PENDIENTE_RECOJO' THEN @cantidad ELSE @pendiente END;
  -- La asociación aporta su propio cupo; no consume existencias certificadas de la UOT.
  IF @origen='UOT'
  BEGIN
    SELECT @stock=existencia_certificada FROM comercial.JabaStockUotE4 WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=@uot;
    IF @stock IS NULL THROW 51456,N'Primero certifique el stock físico de jabas de esta UOT.',1;
    SELECT @entregadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0)
     FROM comercial.CampaniaJabaPlan J JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
     JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
     WHERE C.uot_id=@uot AND C.origen_jabas='UOT' AND J.activo=1 AND J.estado='ENTREGADA';
    SELECT @existentes=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
     FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
     JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
     JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
     LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
     WHERE C.uot_id=@uot AND A.estado=1;
    IF @entregadas+@existentes+@entrega>@stock
     THROW 51457,N'No existen suficientes jabas certificadas para entregar al socio.',1;
  END;
  IF @estado='PENDIENTE_RECOJO'
    UPDATE comercial.CampaniaJabaPlan SET estado='ENTREGADA',fecha_entrega=SYSUTCDATETIME(),
      version=version+1,usuario_modifica_id=@usuario
      WHERE campania_jaba_plan_id=@id AND estado='PENDIENTE_RECOJO';
  ELSE
    UPDATE comercial.CampaniaJabaPlan SET cantidad=cantidad+@entrega,
      cantidad_ajuste_pendiente=0,comentario_ajuste_pendiente=NULL,
      version=version+1,usuario_modifica_id=@usuario
      WHERE campania_jaba_plan_id=@id AND estado='ENTREGADA' AND cantidad_ajuste_pendiente=@entrega;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaJabaPlan',@id,'ENTREGAR_JABAS',
      (SELECT @entrega cantidadEntregada,@cantidad cantidadAnterior,@estado estadoAnterior FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId,@participacion participacionId,
    CASE WHEN @estado='PENDIENTE_RECOJO' THEN @cantidad ELSE @cantidad+@entrega END cantidad,
    'ENTREGADA' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta) VALUES(@usuario,@clave,'ENTREGAR_JABAS_PLAN',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Jabas entregadas al participante.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='JABAS_PLAN_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo confirmar la entrega de jabas.' END;
 END CATCH;
END;
GO
