IF OBJECT_ID(N'[comercial].[PA_CampaniaSocioSancion_Upd_Asignar]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaSocioSancion_Upd_Asignar];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaSocioSancion_Upd_Asignar
' Descripción            : Gestiona campania socio sancion: asignar.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaSocioSancion_Upd_Asignar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo completar la operación.',
   @cCodigoRespuesta='PA_CampaniaSocioSancion_Upd_Asignar_ERROR',@nHttpRespuesta=400;
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
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE participacion_campania_socio_id=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')) AND campania_venta_id=@camp AND estado=1 AND estado_participacion='ACTIVO') THROW 52087,N'Socio fuera de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='SANCIONES_APLICAR',
    @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
    @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
    @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
    @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'SANCIONES_APLICAR')<>1
    THROW 52082,N'No tiene permisos para esta operación.',1;
  IF @clave IS NULL THROW 52083,N'Falta la clave de solicitud.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'PA_CampaniaSocioSancion_Upd_Asignar|',COALESCE(JSON_QUERY(@cJson,'$.filtros'),N''),N'|',COALESCE(JSON_QUERY(@cJson,'$.datos'),N'')));
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
  DECLARE @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
   @tarifa BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.tarifaId')),
   @alcance VARCHAR(10)=JSON_VALUE(@cJson,'$.datos.alcance'),
   @cantidad INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidad')),
   @comentario NVARCHAR(500)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.comentario')),N''),
   @cantidadPlan INT,@numeroInicio INT,@numeroFin INT,@socioSancion BIGINT;
  IF @comentario IS NULL OR LEN(@comentario)<10 OR @alcance IS NULL OR @alcance NOT IN('TODAS','CANTIDAD')
    THROW 52096,N'Indique el motivo de la sanción (mínimo 10 caracteres) y su alcance.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado_proceso IN('ACTIVA','PLANIFICACION'))
    THROW 52091,N'La campaña está cerrada.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaSancionTarifa T JOIN comercial.CatalogoSancionVenta C
     ON C.sancion_venta_id=T.sancion_venta_id WHERE T.campania_sancion_tarifa_id=@tarifa AND T.campania_venta_id=@camp AND T.activo=1 AND C.activo=1)
    THROW 52092,N'La sanción no está habilitada en esta campaña.',1;
  SELECT @cantidadPlan=J.cantidad FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
   WHERE J.participacion_campania_socio_id=@part AND J.activo=1 AND J.recepcion_confirmada=0;
  IF @cantidadPlan IS NULL THROW 52097,N'El socio ya confirmó su recepción o no tiene jabas.',1;
  SELECT @numeroInicio=COALESCE(MAX(R.numero_jaba),0)+1 FROM comercial.CampaniaJabaRecepcion R
    JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
    WHERE J.participacion_campania_socio_id=@part;
  IF @numeroInicio>@cantidadPlan THROW 52097,N'No quedan jabas por registrar.',1;
  IF @alcance='CANTIDAD' AND (@cantidad IS NULL OR @cantidad<1 OR @cantidad>@cantidadPlan-@numeroInicio+1)
    THROW 52098,N'La cantidad supera las jabas pendientes del socio.',1;
  -- 'TODAS' cubre las jabas asignadas AHORA, no futuras ampliaciones del cupo.
  SET @numeroFin=CASE WHEN @alcance='TODAS' THEN @cantidadPlan ELSE @numeroInicio+@cantidad-1 END;
  SELECT @socioSancion=campania_socio_sancion_id FROM comercial.CampaniaSocioSancion WITH(UPDLOCK,HOLDLOCK)
   WHERE participacion_campania_socio_id=@part;
  IF @socioSancion IS NOT NULL AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaPrecioSancion WHERE campania_socio_sancion_id=@socioSancion)
    THROW 52099,N'La sanción ya afectó pesajes: el histórico es inmutable.',1;
  IF @socioSancion IS NULL
  BEGIN
    INSERT comercial.CampaniaSocioSancion(campania_sancion_tarifa_id,participacion_campania_socio_id,desde_numero,hasta_numero,alcance,comentario,usuario_registro_id)
      VALUES(@tarifa,@part,@numeroInicio,@numeroFin,@alcance,@comentario,@usuario);
    SET @socioSancion=SCOPE_IDENTITY();
  END
  ELSE UPDATE comercial.CampaniaSocioSancion SET campania_sancion_tarifa_id=@tarifa,desde_numero=@numeroInicio,
    hasta_numero=@numeroFin,alcance=@alcance,comentario=@comentario,activo=1,
    usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME() WHERE campania_socio_sancion_id=@socioSancion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaSocioSancion',@socioSancion,'ASIGNAR_SANCION',
      (SELECT @part participacionId,@tarifa tarifaId,@numeroInicio desdeNumero,@numeroFin hastaNumero,@alcance alcance,@comentario comentario FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @socioSancion asignacionId,@numeroInicio desdeNumero,@numeroFin hastaNumero FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CampaniaSocioSancion_Upd_Asignar',@hash,@cDatos);
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
