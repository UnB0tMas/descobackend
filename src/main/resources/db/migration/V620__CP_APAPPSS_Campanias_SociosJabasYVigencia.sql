-- DESCO / APAPPSS: normalización de campañas y distribución mínima de jabas.
-- No se cambian migraciones aplicadas; cada PA mantiene una responsabilidad.
-- Incluir socio + reservar 1 jaba y retirar + liberar reserva son transacciones indivisibles.
-- Hora de validación del periodo: fecha local America/Lima (UTC-05).

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
  @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@cantidad INT,
  @cupo INT,@reservadas BIGINT,@operativas BIGINT,
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
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
      OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
    THROW 51476,N'No tiene permiso para incorporar socios y reservar jabas.',1;
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
  -- La selección es válida exclusivamente entre ambas fechas (hora local de Perú).
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
      AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 51481,N'Solo se incorporan socios durante las fechas de campaña.',1;
  SELECT @cupo=K.cupo_jabas FROM comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK)
    WHERE K.campania_venta_id=@camp;
  IF @cupo IS NULL THROW 51482,N'Configure primero el cupo de jabas.',1;
  SELECT @reservadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0)
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado<>'DEVUELTA';
  SELECT @operativas=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0)
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1;
  IF @reservadas+@operativas+(SELECT COUNT(1) FROM @ids)>@cupo
    THROW 51483,N'El cupo no alcanza para reservar al menos una jaba por nuevo socio.',1;
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
  -- Una reserva inicial por socio forma parte de la misma transacción de incorporación.
  -- Única operación de negocio indivisible: participante activo => al menos una jaba.
  IF EXISTS(SELECT 1 FROM @ids I
    JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=@camp AND P.socio_asociacion_id=I.socio_asociacion_id
    JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id
    WHERE J.activo=1 AND J.estado='ENTREGADA')
    THROW 51484,N'Un socio tiene jabas ya entregadas y no puede reincorporarse.',1;
  UPDATE J SET J.cantidad=1,J.estado='PENDIENTE_RECOJO',J.activo=1,
    J.fecha_entrega=NULL,J.fecha_devolucion=NULL,J.version=J.version+1,J.usuario_modifica_id=@usuario
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN @ids I ON I.socio_asociacion_id=P.socio_asociacion_id
    WHERE P.campania_venta_id=@camp AND (J.activo=0 OR J.estado='DEVUELTA');
  INSERT comercial.CampaniaJabaPlan(participacion_campania_socio_id,cantidad,estado,usuario_registro_id)
    SELECT P.participacion_campania_socio_id,1,'PENDIENTE_RECOJO',@usuario
    FROM comercial.ParticipacionCampaniaSocio P
    JOIN @ids I ON I.socio_asociacion_id=P.socio_asociacion_id
    WHERE P.campania_venta_id=@camp
      AND NOT EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J
        WHERE J.participacion_campania_socio_id=P.participacion_campania_socio_id);
  IF EXISTS(SELECT 1 FROM @ids I
    JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=@camp AND P.socio_asociacion_id=I.socio_asociacion_id
    LEFT JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id
      AND J.activo=1 AND J.estado='PENDIENTE_RECOJO' AND J.cantidad>=1
    WHERE J.campania_jaba_plan_id IS NULL)
    THROW 51485,N'No se pudieron reservar las jabas mínimas de todos los socios.',1;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Cantidad
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
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
 @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@id BIGINT,@actual INT,@estado VARCHAR(20),
 @cupo INT,@ocupadas BIGINT,@reservadas BIGINT,@nuevaVersion BIGINT,@fecha DATETIME2(0)=SYSUTCDATETIME();
 BEGIN TRY
  IF @camp IS NULL OR @participacion IS NULL OR @cantidad IS NULL OR @cantidad NOT BETWEEN 1 AND 100000 OR @clave IS NULL
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
  SELECT @id=campania_jaba_plan_id,@actual=cantidad,@estado=estado,@nuevaVersion=version
   FROM comercial.CampaniaJabaPlan WITH(UPDLOCK,HOLDLOCK) WHERE participacion_campania_socio_id=@participacion;
  IF @id IS NOT NULL AND @estado<>'PENDIENTE_RECOJO' AND @cantidad<>@actual
   THROW 51437,N'No puede cambiar una asignación entregada o devuelta.',1;
  IF @version IS NOT NULL AND @id IS NOT NULL AND @version<>@nuevaVersion
   THROW 51438,N'La asignación fue modificada. Actualice el detalle.',1;
  SELECT @reservadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0)
   FROM comercial.CampaniaJabaPlan J JOIN comercial.ParticipacionCampaniaSocio P
   ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado<>'DEVUELTA' AND P.participacion_campania_socio_id<>@participacion;
  SELECT @ocupadas=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0)
   FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   WHERE O.campania_venta_id=@camp AND A.estado=1;
  IF @reservadas+@ocupadas+@cantidad>@cupo
   THROW 51439,N'La cantidad solicitada excede el cupo libre de campaña.',1;
  IF @id IS NULL
  BEGIN
   INSERT comercial.CampaniaJabaPlan(participacion_campania_socio_id,cantidad,estado,usuario_registro_id)
    VALUES(@participacion,@cantidad,'PENDIENTE_RECOJO',@usuario);
   SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
   IF @estado<>'PENDIENTE_RECOJO'
    THROW 51437,N'La entrega no permite modificar cantidades.',1;
   UPDATE comercial.CampaniaJabaPlan
    SET cantidad=@cantidad,activo=1,version=version+1,usuario_modifica_id=@usuario
    WHERE campania_jaba_plan_id=@id;
  END;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaPlan',@id,'AJUSTAR_ASIGNACION',
     (SELECT @participacion participacionId,@actual cantidadAnterior,@cantidad cantidadNueva FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId,@participacion participacionId,@cantidad cantidad,'PENDIENTE_RECOJO' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Entregar
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
 @stock INT,@existentes BIGINT,@entregadas BIGINT;
 BEGIN TRY
  IF @camp IS NULL OR @participacion IS NULL OR @clave IS NULL THROW 51450,N'Indique la campaña y el participante.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA');
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
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
    AND CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())) BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 51458,N'La entrega de jabas solo puede confirmarse durante la campaña.',1;
  SELECT @id=J.campania_jaba_plan_id,@cantidad=J.cantidad FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@participacion
     AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1 AND J.estado='PENDIENTE_RECOJO';
  IF @id IS NULL THROW 51455,N'El socio no tiene jabas pendientes de recojo.',1;
  SELECT @stock=existencia_certificada FROM comercial.JabaStockUotE4 WITH(UPDLOCK,HOLDLOCK) WHERE uot_id=@uot;
  IF @stock IS NULL THROW 51456,N'Primero certifique el stock físico de jabas de esta UOT.',1;
  SELECT @entregadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0)
   FROM comercial.CampaniaJabaPlan J JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
   WHERE C.uot_id=@uot AND J.activo=1 AND J.estado='ENTREGADA';
  SELECT @existentes=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
   FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
   JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
   JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
   LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
   WHERE C.uot_id=@uot AND A.estado=1;
  IF @entregadas+@existentes+@cantidad>@stock
   THROW 51457,N'No existen suficientes jabas certificadas para entregar al socio.',1;
  UPDATE comercial.CampaniaJabaPlan SET estado='ENTREGADA',fecha_entrega=SYSUTCDATETIME(),version=version+1,usuario_modifica_id=@usuario
   WHERE campania_jaba_plan_id=@id AND estado='PENDIENTE_RECOJO';
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaJabaPlan',@id,'ENTREGAR_JABAS',(SELECT @cantidad cantidad FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @id asignacionId,@participacion participacionId,@cantidad cantidad,'ENTREGADA' estado FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Upd_Datos
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo actualizar la campaña.',@cCodigoRespuesta='CAMPANIA_EDICION_INVALIDA',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @comprador BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.compradorId')),
  @empresa BIGINT,@uot BIGINT,@asociacion BIGINT,@estado VARCHAR(24),@usuario BIGINT,@sesion BIGINT,
  @dispositivo BIGINT,@empleado BIGINT,@modulo INT,@corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,
  @ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @nombre NVARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
  @inicio DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaInicio')),
  @fin DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaFin')),
  @observacion NVARCHAR(400)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@appLock INT,
  @antes NVARCHAR(MAX),@despues NVARCHAR(MAX),@aud BIGINT,@trans BIGINT,
  @inicioAnterior DATE,@finAnterior DATE,@compradorAnterior BIGINT,
  @recursoLock NVARCHAR(255),@identificador NVARCHAR(200);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @comprador IS NULL
    OR @nombre IS NULL OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL
    OR @fin<@hoy OR @fin<@inicio OR LEN(COALESCE(@observacion,N''))>400
    THROW 51901,N'Complete correctamente el comprador, nombre y fechas de la campaña.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 THROW 51902,N'No tiene permiso para editar campañas.',1;
  SELECT @uot=C.uot_id,@asociacion=C.asociacion_id FROM comercial.CampaniaVenta C
    WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
    THROW 51902,N'No tiene acceso a esta campaña.',1;
  IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.Empresa AE ON AE.empresa_id=CU.empresa_id AND AE.ruc='20602771394' AND AE.estado=1
    JOIN org.Asociacion A ON A.asociacion_id=AE.empresa_id AND A.estado=1
    JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
      AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=@hoy)
      AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=@hoy))
    THROW 51903,N'La UOT no tiene convenio APAPPSS vigente.',1;
  SELECT @empresa=CASE WHEN B.tipo='EMPRESA' THEN B.empresa_id ELSE NULL END
  FROM comercial.CompradorAPAPPSS B
  LEFT JOIN org.Empresa E ON E.empresa_id=B.empresa_id
  LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
  WHERE B.comprador_apappss_id=@comprador AND B.uot_id=@uot AND B.estado=1
    AND ((B.tipo='EMPRESA' AND E.empresa_id IS NOT NULL AND E.estado=1)
      OR (B.tipo='PERSONA' AND P.persona_id IS NOT NULL AND P.estado=1));
  IF @@ROWCOUNT<>1 OR (@empresa IS NOT NULL AND @empresa=@asociacion)
    THROW 51904,N'El comprador no está disponible para esta UOT.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'CAMPANIA_EDICION|',@camp,N'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  SET @recursoLock=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@recursoLock,
    @LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51905,N'La campaña está siendo modificada. Reintente.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 51906,N'La clave corresponde a otra operación.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Edición procesada anteriormente.',@cCodigoRespuesta='CAMPANIA_ACTUALIZADA',@nHttpRespuesta=200;
    COMMIT TRANSACTION; RETURN;
  END;
  SELECT @estado=C.estado_proceso,@inicioAnterior=C.fecha_inicio,@finAnterior=C.fecha_fin,
     @compradorAnterior=C.comprador_apappss_id
    FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.uot_id=@uot AND C.estado=1;
  IF @estado IS NULL OR @estado NOT IN('PLANIFICACION','ACTIVA')
    THROW 51907,N'La campaña ya no admite cambios.',1;
  IF @inicio<@hoy AND @inicio<>@inicioAnterior
    THROW 51908,N'No puede cambiar el inicio a una fecha anterior a hoy.',1;
  -- En campaña activa solo se actualizan nombre y observación; se respeta la relación comercial.
  IF @estado='ACTIVA' AND (@inicio<>@inicioAnterior OR @fin<>@finAnterior
       OR ISNULL(@comprador,-1)<>ISNULL(@compradorAnterior,-1))
    THROW 51909,N'En una campaña activa solo puede modificar nombre y observación.',1;
  SET @antes=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  UPDATE comercial.CampaniaVenta SET comprador_apappss_id=@comprador,empresa_compradora_id=@empresa,
   nombre=@nombre,fecha_inicio=@inicio,fecha_fin=@fin,observacion=@observacion
   WHERE campania_venta_id=@camp;
  SET @despues=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SET @identificador=CONVERT(NVARCHAR(200),@camp);
  EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @usuario,@sesion,@dispositivo,@modulo,
    'EDITAR','comercial','CampaniaVenta',@identificador,@antes,@despues,
    NULL,NULL,NULL,NULL,@ip,@corr,@sol,@endpoint,@aud OUTPUT,@trans OUTPUT;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaVenta',@camp,'EDITAR_DATOS',@despues,@usuario);
  SET @cDatos=(SELECT @camp campaniaVentaId,@comprador compradorId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'EDITAR_CAMPANIA',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Campaña actualizada.',@cCodigoRespuesta='CAMPANIA_ACTUALIZADA',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CAMPANIA_EDICION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo actualizar la campaña.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Upd_RetirarSocio
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
