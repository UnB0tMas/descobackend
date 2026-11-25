IF OBJECT_ID(N'[comercial].[PA_CampaniaPlan_Upd_RetirarSocio]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaPlan_Upd_RetirarSocio];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaPlan_Upd_RetirarSocio
' Descripción            : Gestiona campania plan: retirar socio.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaPlan_Upd_RetirarSocio
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo retirar el socio.',@cCodigoRespuesta='SOCIO_RETIRO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @motivo NVARCHAR(500)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.motivo')),N''),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,@prev VARBINARY(32),@hash VARBINARY(32),
  @respuesta NVARCHAR(MAX),@reserva BIGINT,@cantidad INT,
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  IF @camp IS NULL OR @part IS NULL OR @clave IS NULL OR @motivo IS NULL OR LEN(@motivo) NOT BETWEEN 5 AND 500
    THROW 51930,N'Indique el socio y un motivo de retiro válido.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta
    WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51931,N'La campaña no permite retirar participantes.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PARTICIPANTES_RETIRAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_RETIRAR')<>1
    THROW 51932,N'No tiene permiso para retirar socios.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'RETIRAR_SOCIO_PLAN|',@camp,'|',@part,'|',@motivo));
  BEGIN TRANSACTION;
  DECLARE @recurso NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 51933,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51934,N'Esta clave corresponde a una solicitud diferente.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Retiro procesado anteriormente.',
    @cCodigoRespuesta='SOCIO_RETIRO_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION; RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
      AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 51935,N'Solo puede retirar socios durante la vigencia de la campaña.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
    WHERE P.participacion_campania_socio_id=@part AND P.campania_venta_id=@camp
      AND P.estado=1 AND P.estado_participacion='ACTIVO')
    THROW 51936,N'El socio no está inscrito como participante activo.',1;
  IF EXISTS(SELECT 1 FROM comercial.EntregaSocio E
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
    WHERE OS.participacion_campania_socio_id=@part AND E.estado=1 AND E.estado_proceso='CONFIRMADA')
    THROW 51937,N'El socio ya tiene entregas confirmadas.',1;
  IF EXISTS(SELECT 1 FROM comercial.OperativoSocio OS
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE OS.participacion_campania_socio_id=@part AND OS.estado=1 AND O.estado=1
      AND OS.estado_participacion='PROGRAMADO')
    THROW 51938,N'El socio está programado en un operativo y no puede retirarse.',1;
  SELECT @reserva=J.campania_jaba_plan_id,@cantidad=J.cantidad
    FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    WHERE J.participacion_campania_socio_id=@part AND J.activo=1 AND J.estado='PENDIENTE_RECOJO';
  IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    WHERE J.participacion_campania_socio_id=@part AND J.activo=1 AND J.estado='ENTREGADA')
    THROW 51939,N'No puede retirar socios con jabas entregadas.',1;
  IF @reserva IS NOT NULL
    UPDATE comercial.CampaniaJabaPlan SET activo=0,version=version+1,usuario_modifica_id=@usuario
      WHERE campania_jaba_plan_id=@reserva AND estado='PENDIENTE_RECOJO';
  UPDATE comercial.ParticipacionCampaniaSocio SET estado_participacion='RETIRADO'
    WHERE participacion_campania_socio_id=@part AND campania_venta_id=@camp AND estado=1 AND estado_participacion='ACTIVO';
  IF @@ROWCOUNT<>1 THROW 51940,N'No se pudo retirar al socio.',1;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'ParticipacionCampaniaSocio',@part,'RETIRAR_SOCIO',
      (SELECT @motivo motivo,@cantidad jabasLiberadas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaId,@part participacionId,ISNULL(@cantidad,0) jabasLiberadas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'RETIRAR_SOCIO_PLAN',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Socio retirado y jabas pendientes liberadas.',@cCodigoRespuesta='SOCIO_RETIRO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='SOCIO_RETIRO_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51930 AND 51949 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51930 AND 51949 THEN LEFT(ERROR_MESSAGE(),300)
      ELSE N'No se pudo retirar el participante.' END;
 END CATCH;
END;
GO
