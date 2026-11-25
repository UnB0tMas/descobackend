IF OBJECT_ID(N'[comercial].[PA_CampaniaJabaPlan_Upd_Cantidad]') IS NOT NULL
    DROP PROCEDURE [comercial].[PA_CampaniaJabaPlan_Upd_Cantidad];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del PA            : comercial.PA_CampaniaJabaPlan_Upd_Cantidad
' Descripción            : Actualiza campania jaba plan para cantidad.
' Aplicativo / Módulo    : DESCO / comercial
*******************************************************************************************************/
CREATE   PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Cantidad
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo asignar jabas.',@cCodigoRespuesta='JABAS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @participacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
 @cantidad INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cantidad')),
 @version BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version')),
 @comentario NVARCHAR(4000)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.comentario')),N''),
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
 @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@id BIGINT,@actual INT,@estado VARCHAR(20),
 @cupo INT,@ocupadas BIGINT,@reservadas BIGINT,@nuevaVersion BIGINT,@pendiente INT=0,@delta INT,@ocupacion INT,
 @registrosMax INT=0,@fecha DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  IF @camp IS NULL OR @participacion IS NULL OR @cantidad IS NULL OR @cantidad NOT BETWEEN 0 AND 100000 OR @clave IS NULL
   THROW 51430,N'Indique participante y cantidad válida.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51431,N'La campaña no permite asignar jabas.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
   THROW 51432,N'Sin permisos para asignar jabas de esta campaña.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT('CANTIDAD|',@camp,'|',@participacion,'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51433,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK) WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51434,N'Esta clave ya se usó para otro cambio.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Asignación procesada anteriormente.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
    AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 51441,N'La asignación solo puede modificarse durante la campaña.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
    WHERE P.participacion_campania_socio_id=@participacion AND P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO')
   THROW 51435,N'El socio no está inscrito como participante activo.',1;
  SELECT @cupo=cupo_jabas FROM comercial.CampaniaControlE4 WITH(UPDLOCK,HOLDLOCK) WHERE campania_venta_id=@camp;
  IF @cupo IS NULL THROW 51436,N'Configure primero la cantidad de jabas de la campaña.',1;
  SELECT @id=campania_jaba_plan_id,@actual=cantidad,@estado=estado,@nuevaVersion=version,
    @pendiente=cantidad_ajuste_pendiente
   FROM comercial.CampaniaJabaPlan WITH(UPDLOCK,HOLDLOCK) WHERE participacion_campania_socio_id=@participacion;
  IF @id IS NULL AND @cantidad=0 THROW 51437,N'La asignación inicial requiere al menos una jaba.',1;
  IF @estado='DEVUELTA' THROW 51437,N'Las jabas ya fueron devueltas.',1;
  IF @estado='PENDIENTE_RECOJO' AND @cantidad=0
   THROW 51437,N'La reserva inicial requiere al menos una jaba.',1;
  IF @estado='ENTREGADA' AND (@comentario IS NULL OR LEN(@comentario) NOT BETWEEN 5 AND 500)
   THROW 51437,N'Indique el motivo del ajuste (mínimo 5 caracteres).',1;
  IF @estado='ENTREGADA' AND @cantidad=@actual AND ISNULL(@pendiente,0)=0
   THROW 51437,N'La cantidad no presenta cambios.',1;
  IF @estado='ENTREGADA'
  BEGIN
    SELECT @registrosMax=COALESCE(MAX(numero_jaba),0)
      FROM comercial.CampaniaJabaRecepcion WITH(UPDLOCK,HOLDLOCK)
      WHERE campania_jaba_plan_id=@id;
    IF @cantidad<@registrosMax
      THROW 51437,N'No puede reducir la cantidad por debajo de las jabas registradas en venta.',1;
  END;
  IF @version IS NOT NULL AND @id IS NOT NULL AND @version<>@nuevaVersion
   THROW 51438,N'La asignación fue modificada. Actualice el detalle.',1;
  SELECT @reservadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+
    CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0)
   FROM comercial.CampaniaJabaPlan J JOIN comercial.ParticipacionCampaniaSocio P
   ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado<>'DEVUELTA' AND P.participacion_campania_socio_id<>@participacion;
  SELECT @ocupadas=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0)
   FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   WHERE O.campania_venta_id=@camp AND A.estado=1;
  SET @ocupacion=CASE WHEN @estado='ENTREGADA' AND @cantidad<@actual THEN @actual ELSE @cantidad END;
  IF @reservadas+@ocupadas+@ocupacion>@cupo
   THROW 51439,N'La cantidad solicitada excede el cupo libre de campaña.',1;
  IF @id IS NULL
  BEGIN
   INSERT comercial.CampaniaJabaPlan(participacion_campania_socio_id,cantidad,estado,usuario_registro_id)
    VALUES(@participacion,@cantidad,'PENDIENTE_RECOJO',@usuario);
   SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE IF @estado='PENDIENTE_RECOJO'
  BEGIN
   UPDATE comercial.CampaniaJabaPlan
    SET cantidad=@cantidad,activo=1,version=version+1,usuario_modifica_id=@usuario
    WHERE campania_jaba_plan_id=@id;
  END
  ELSE
  BEGIN
   SET @delta=@cantidad-@actual;
   UPDATE comercial.CampaniaJabaPlan
    SET cantidad_ajuste_pendiente=@delta,
        comentario_ajuste_pendiente=CASE WHEN @delta=0 THEN NULL ELSE @comentario END,
        version=version+1,usuario_modifica_id=@usuario
    WHERE campania_jaba_plan_id=@id AND estado='ENTREGADA';
  END;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaPlan',@id,
     CASE WHEN @estado='ENTREGADA' THEN 'SOLICITAR_AJUSTE_JABAS' ELSE 'AJUSTAR_ASIGNACION' END,
     (SELECT @participacion participacionId,@actual cantidadFisica,@cantidad cantidadSolicitada,
             @comentario comentario FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId,@participacion participacionId,
    CASE WHEN @estado='ENTREGADA' THEN @actual ELSE @cantidad END cantidad,
    CASE WHEN @estado='ENTREGADA' AND @delta>0 THEN 'PENDIENTE_RECOJO'
         WHEN @estado='ENTREGADA' AND @delta<0 THEN 'PENDIENTE_DEVOLUCION'
         WHEN @estado='ENTREGADA' THEN 'ENTREGADA' ELSE 'PENDIENTE_RECOJO' END estado,
    @cantidad cantidadObjetivo FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta) VALUES(@usuario,@clave,'JABAS_PLAN_CANTIDAD',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Asignación guardada.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='JABAS_PLAN_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo asignar las jabas.' END;
 END CATCH;
END;
GO
