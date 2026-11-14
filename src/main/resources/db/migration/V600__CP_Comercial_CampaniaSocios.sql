-- APAPPSS: listar elegibles e incorporar en lote, con reactivación sin duplicados.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Sel_SociosElegibles
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar socios elegibles.',@cCodigoRespuesta='SOCIOS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  SELECT @uot=uot_id,@asociacion=asociacion_id FROM comercial.CampaniaVenta
    WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL THROW 51470,N'La campaña no está disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PARTICIPANTES_LISTAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_LISTAR')<>1
   THROW 51471,N'Sin permiso para consultar participantes.',1;
  SET @cDatos=(SELECT @camp campaniaId,
   JSON_QUERY((SELECT SA.socio_asociacion_id socioAsociacionId,
     CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) nombre,
     PE.numero_documento numeroDocumento
    FROM org.SocioAsociacion SA JOIN org.Socio S ON S.socio_id=SA.socio_id AND S.estado=1
    JOIN org.Persona PE ON PE.persona_id=S.socio_id AND PE.estado=1
    WHERE SA.asociacion_id=@asociacion AND SA.estado=1 AND SA.situacion_membresia='ACTIVO'
      AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
      AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
      AND NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
       WHERE P.campania_venta_id=@camp AND P.socio_asociacion_id=SA.socio_asociacion_id
        AND P.estado=1 AND P.estado_participacion='ACTIVO')
    ORDER BY PE.apellido_paterno,PE.nombres,SA.socio_asociacion_id FOR JSON PATH)) socios
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Socios elegibles listados.',@cCodigoRespuesta='SOCIOS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='SOCIOS_PLAN_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 400 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar socios elegibles.' END;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Ins_SociosLote
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo agregar los socios.',@cCodigoRespuesta='SOCIOS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@asociacion BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@cantidad INT;
 DECLARE @ids TABLE(socio_asociacion_id BIGINT PRIMARY KEY);
 BEGIN TRY
  SELECT @uot=uot_id,@asociacion=asociacion_id FROM comercial.CampaniaVenta
   WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @uot IS NULL OR @clave IS NULL THROW 51472,N'Campaña o solicitud no válida.',1;
  IF JSON_QUERY(@cJson,'$.datos.sociosIds') IS NULL OR
    (SELECT COUNT(1) FROM OPENJSON(@cJson,'$.datos.sociosIds')) NOT BETWEEN 1 AND 100
   THROW 51473,N'Seleccione entre 1 y 100 socios.',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.sociosIds')
    WHERE [type]<>2 OR TRY_CONVERT(BIGINT,[value]) IS NULL OR TRY_CONVERT(BIGINT,[value])<=0)
   THROW 51474,N'Hay identificadores de socios inválidos.',1;
  IF EXISTS(SELECT [value] FROM OPENJSON(@cJson,'$.datos.sociosIds') GROUP BY [value] HAVING COUNT(1)>1)
   THROW 51475,N'La selección incluye socios repetidos.',1;
  INSERT INTO @ids SELECT CONVERT(BIGINT,[value]) FROM OPENJSON(@cJson,'$.datos.sociosIds');
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PARTICIPANTES_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_CREAR')<>1
    THROW 51476,N'No tiene permiso para agregar socios.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'AGREGAR_SOCIOS|',@camp,'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51477,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51478,N'Esta clave de solicitud ya se utilizó.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Socios agregados anteriormente.',@cCodigoRespuesta='SOCIOS_PLAN_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  IF EXISTS(SELECT 1 FROM @ids I LEFT JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=I.socio_asociacion_id
    AND SA.asociacion_id=@asociacion AND SA.estado=1 AND SA.situacion_membresia='ACTIVO'
    AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME()) AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
    LEFT JOIN org.Socio S ON S.socio_id=SA.socio_id AND S.estado=1
    LEFT JOIN org.Persona PE ON PE.persona_id=S.socio_id AND PE.estado=1
    WHERE PE.persona_id IS NULL)
   THROW 51479,N'Uno o más socios no pertenecen activamente a la asociación.',1;
  IF EXISTS(SELECT 1 FROM @ids I JOIN comercial.ParticipacionCampaniaSocio P WITH(UPDLOCK,HOLDLOCK)
    ON P.campania_venta_id=@camp AND P.socio_asociacion_id=I.socio_asociacion_id
    WHERE P.estado=1 AND P.estado_participacion='ACTIVO')
   THROW 51480,N'Uno o más socios ya participan en la campaña.',1;
  UPDATE P SET estado=1,estado_participacion='ACTIVO',fecha_registro=SYSUTCDATETIME()
   FROM comercial.ParticipacionCampaniaSocio P JOIN @ids I ON I.socio_asociacion_id=P.socio_asociacion_id
   WHERE P.campania_venta_id=@camp AND (P.estado=0 OR P.estado_participacion='RETIRADO');
  INSERT comercial.ParticipacionCampaniaSocio(campania_venta_id,socio_asociacion_id,fecha_registro,estado_participacion,estado)
   SELECT @camp,I.socio_asociacion_id,SYSUTCDATETIME(),'ACTIVO',1 FROM @ids I
   WHERE NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio P
     WHERE P.campania_venta_id=@camp AND P.socio_asociacion_id=I.socio_asociacion_id);
  SELECT @cantidad=COUNT(1) FROM @ids;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaVenta',@camp,'INCLUIR_SOCIOS',JSON_QUERY(@cJson,'$.datos'),@usuario);
  SET @cDatos=(SELECT @camp campaniaId,@cantidad incorporados FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta) VALUES(@usuario,@clave,'SOCIOS_LOTE_PLAN',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Socios incorporados.',@cCodigoRespuesta='SOCIOS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @bResultado=0,@cDatos=NULL,@cCodigoRespuesta='SOCIOS_PLAN_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo incorporar socios.' END;
 END CATCH;
END;
GO
