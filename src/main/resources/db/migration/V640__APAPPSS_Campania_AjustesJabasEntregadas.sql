-- DESCO/APAPPSS. V640: cambios de jabas despues de entrega con trazabilidad.
-- Cantidad refleja jabas fisicamente entregadas; el ajuste pendiente aun NO modifica esa cantidad.
-- Los estados PENDIENTE_RECOJO (ampliacion) y PENDIENTE_DEVOLUCION se calculan en consultas.
IF COL_LENGTH(N'comercial.CampaniaJabaPlan',N'cantidad_ajuste_pendiente') IS NULL
  ALTER TABLE comercial.CampaniaJabaPlan ADD cantidad_ajuste_pendiente INT NOT NULL
    CONSTRAINT DF_CampaniaJabaPlan_AjustePendiente DEFAULT(0) WITH VALUES;
GO
IF COL_LENGTH(N'comercial.CampaniaJabaPlan',N'comentario_ajuste_pendiente') IS NULL
  ALTER TABLE comercial.CampaniaJabaPlan ADD comentario_ajuste_pendiente NVARCHAR(500) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'comercial.CampaniaJabaPlan')
 AND name=N'CK_CampaniaJabaPlan_Cantidad')
 ALTER TABLE comercial.CampaniaJabaPlan DROP CONSTRAINT CK_CampaniaJabaPlan_Cantidad;
GO
ALTER TABLE comercial.CampaniaJabaPlan WITH CHECK ADD CONSTRAINT CK_CampaniaJabaPlan_Cantidad
 CHECK (cantidad BETWEEN 1 AND 100000 OR (cantidad=0 AND estado='DEVUELTA'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints
               WHERE parent_object_id=OBJECT_ID(N'comercial.CampaniaJabaPlan')
                 AND name=N'CK_CampaniaJabaPlan_AjustePendiente')
  ALTER TABLE comercial.CampaniaJabaPlan WITH CHECK ADD CONSTRAINT CK_CampaniaJabaPlan_AjustePendiente
    CHECK (
      (cantidad_ajuste_pendiente=0 AND comentario_ajuste_pendiente IS NULL)
      OR (estado='ENTREGADA' AND cantidad_ajuste_pendiente<>0
          AND cantidad+cantidad_ajuste_pendiente BETWEEN 0 AND 100000
          AND COALESCE(LEN(TRIM(comentario_ajuste_pendiente)),0) BETWEEN 5 AND 500)
    );
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaPlan_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la campaña.',@cCodigoRespuesta='JABAS_PLAN_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300);
 BEGIN TRY
  IF @camp IS NULL THROW 51410,N'Seleccione una campaña.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 51411,N'Campaña no disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
     OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PARTICIPANTES_LISTAR')<>1
    THROW 51412,N'No puede consultar los participantes de esta campaña.',1;
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.modalidad_venta_id modalidadVentaId,C.origen_jabas origenJabas,
    C.comprador_apappss_id compradorId,B.tipo tipoComprador,
    COALESCE(CASE WHEN B.tipo='PERSONA' THEN NULLIF(TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))),N'') ELSE EB.razon_social END,EC.razon_social) compradorNombre,
    (SELECT TOP(1) CC.condicion_comercial_id FROM comercial.CondicionComercial CC
     WHERE CC.modalidad_venta_id=C.modalidad_venta_id
      AND CC.codigo=CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),C.modalidad_venta_id)) AND CC.estado=1) condicionComercialId,
    K.cupo_jabas cupoJabas,K.tara_kg taraKg,
   S.existencia_certificada stockFisico,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado<>'DEVUELTA') jabasComprometidas,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0)
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=@camp AND A.estado=1) jabasOperativo,
   JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,
     SA.socio_asociacion_id socioAsociacionId,PE.numero_documento documento,
     CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,
     P.estado_participacion estadoParticipacion,J.campania_jaba_plan_id asignacionId,
     J.cantidad cantidadJabas,
     CASE WHEN J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente>0 THEN 'PENDIENTE_RECOJO'
          WHEN J.estado='ENTREGADA' AND J.cantidad_ajuste_pendiente<0 THEN 'PENDIENTE_DEVOLUCION'
          ELSE J.estado END estadoJabas,
     J.cantidad+J.cantidad_ajuste_pendiente cantidadObjetivo,
     J.cantidad_ajuste_pendiente cantidadAjustePendiente,
     J.comentario_ajuste_pendiente comentarioAjustePendiente,J.version versionJabas
     FROM comercial.ParticipacionCampaniaSocio P JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
     JOIN org.Socio SO ON SO.socio_id=SA.socio_id
     JOIN org.Persona PE ON PE.persona_id=SO.socio_id
     LEFT JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
     WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO'
     ORDER BY PE.apellido_paterno,PE.nombres,P.participacion_campania_socio_id FOR JSON PATH)) participantes
   FROM comercial.CampaniaVenta C
   LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id
   LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
   LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id
   LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id
   LEFT JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id
   LEFT JOIN comercial.JabaStockUotE4 S ON S.uot_id=C.uot_id WHERE C.campania_venta_id=@camp
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Plan de jabas consultado.',@cCodigoRespuesta='JABAS_PLAN_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @bResultado=0,@cCodigoRespuesta='JABAS_PLAN_ERROR',@cDatos=NULL,
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 400 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar el plan de jabas.' END;
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaPlan_Upd_Devolver
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

CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_ValidarCupo
ON comercial.CampaniaControlE4 AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM inserted K
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51420,N'El nuevo cupo es inferior a las jabas reservadas o asignadas.',1;
END;
GO

CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_CompatibilidadOperativo
ON comercial.JabaAsignacion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK) ON K.campania_venta_id=O.campania_venta_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS2 ON OS2.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O2 ON O2.operativo_venta_id=OS2.operativo_venta_id
    WHERE O2.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51422,N'Las jabas reservadas en campaña más las asignadas al operativo exceden el cupo.',1;
 IF EXISTS(SELECT 1 FROM inserted I
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=I.operativo_socio_id
  JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
  JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
  JOIN comercial.JabaStockUotE4 S WITH(UPDLOCK,HOLDLOCK) ON S.uot_id=C.uot_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta K ON K.campania_venta_id=P.campania_venta_id
    WHERE K.uot_id=S.uot_id AND K.origen_jabas='UOT' AND J.activo=1 AND J.estado='ENTREGADA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0) cantidad
    FROM comercial.JabaAsignacion A JOIN comercial.OperativoSocio X ON X.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta OV ON OV.operativo_venta_id=X.operativo_venta_id
    JOIN comercial.CampaniaVenta CV ON CV.campania_venta_id=OV.campania_venta_id
    LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
    WHERE CV.uot_id=S.uot_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>S.existencia_certificada)
  THROW 51423,N'Las jabas entregadas y las retenidas superan las existencias certificadas.',1;
END;
GO

CREATE OR ALTER TRIGGER comercial.TR_CampaniaJabaPlan_ValidarAjusteCupo
ON comercial.CampaniaJabaPlan AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted I
  JOIN comercial.ParticipacionCampaniaSocio PX ON PX.participacion_campania_socio_id=I.participacion_campania_socio_id
  JOIN comercial.CampaniaControlE4 K WITH(UPDLOCK,HOLDLOCK) ON K.campania_venta_id=PX.campania_venta_id
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)+
    CASE WHEN J.cantidad_ajuste_pendiente>0 THEN CONVERT(BIGINT,J.cantidad_ajuste_pendiente) ELSE 0 END),0) cantidad
    FROM comercial.CampaniaJabaPlan J
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=K.campania_venta_id AND J.activo=1 AND J.estado<>'DEVUELTA') R
  CROSS APPLY(SELECT COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-A.cantidad_devuelta),0) cantidad
    FROM comercial.JabaAsignacion A
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    WHERE O.campania_venta_id=K.campania_venta_id AND A.estado=1) E
  WHERE R.cantidad+E.cantidad>K.cupo_jabas)
  THROW 51439,N'Las jabas solicitadas exceden el cupo de la campaña.',1;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaRecepcion_Upd_Registro
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo registrar la jaba.',@cCodigoRespuesta='RECEPCION_REGISTRO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @numero INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.numero')),
  @peso DECIMAL(12,3)=TRY_CONVERT(DECIMAL(12,3),JSON_VALUE(@cJson,'$.datos.pesoBrutoKg')),
  @calibre BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.calibreId')),
  @version INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.version')),
  @observacion NVARCHAR(400)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@asignacion BIGINT,@asignadas INT,@estado VARCHAR(20),@descuento DECIMAL(9,3),@registradas INT,@id BIGINT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),@appLock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @part IS NULL OR @numero IS NULL OR @numero<1
     OR @peso IS NULL OR @peso<0 OR @peso>999999 OR LEN(COALESCE(JSON_VALUE(@cJson,'$.datos.observacion'),N''))>400 OR (@peso=0 AND @calibre IS NOT NULL)
    THROW 52010,N'Ingrese un peso no negativo; una jaba vacía debe tener peso 0.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52011,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
    THROW 52012,N'No tiene permiso para registrar recepciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'RECEPCION_JABA|',@camp,'|',@part,'|',@numero,'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52013,N'Otra operación está modificando las jabas.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 52014,N'Esta solicitud se utilizó con otros datos.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Registro procesado anteriormente.',@cCodigoRespuesta='RECEPCION_JABA_OK',@nHttpRespuesta=200;
   COMMIT TRANSACTION;RETURN;
  END;
  SELECT @descuento=C.descuento_jaba_kg FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
   WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
     AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin;
  IF @@ROWCOUNT<>1 THROW 52015,N'El proceso de venta solo se permite durante las fechas vigentes.',1;
  SET @descuento=COALESCE(@descuento,0);
  SELECT @asignacion=J.campania_jaba_plan_id,@asignadas=J.cantidad,@estado=J.estado
   FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@part
      AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1;
  IF @asignacion IS NULL OR @estado<>'ENTREGADA' OR @numero>@asignadas
    THROW 52016,N'El socio debe haber recibido físicamente sus jabas y el número debe estar asignado.',1;
  IF @peso>0
  BEGIN
    IF @peso<@descuento THROW 52017,N'El peso no puede ser menor que el descuento por jaba.',1;
    IF @calibre IS NULL AND (SELECT COUNT(1) FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1)=1
       SELECT @calibre=campania_calibre_id FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1;
    IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_calibre_id=@calibre AND campania_venta_id=@camp AND activo=1)
       THROW 52018,N'Seleccione un calibre y variedad registrados en esta campaña.',1;
  END;
  IF @peso=0 SET @descuento=0;
  SELECT @id=campania_jaba_recepcion_id FROM comercial.CampaniaJabaRecepcion WITH(UPDLOCK,HOLDLOCK)
   WHERE campania_jaba_plan_id=@asignacion AND numero_jaba=@numero;
  IF @id IS NULL
  BEGIN
    IF @version IS NOT NULL THROW 52019,N'La jaba fue modificada; actualice el listado.',1;
    INSERT comercial.CampaniaJabaRecepcion(campania_jaba_plan_id,numero_jaba,peso_bruto_kg,descuento_jaba_kg,campania_calibre_id,usuario_registro_id,observacion)
      VALUES(@asignacion,@numero,@peso,@descuento,@calibre,@usuario,@observacion);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE THROW 52020,N'La jaba ya fue registrada. Utilice Corregir e indique el motivo.',1;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion;
  IF @registradas=@asignadas AND @estado='ENTREGADA'
    AND NOT EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan WHERE campania_jaba_plan_id=@asignacion AND cantidad_ajuste_pendiente<>0)
    UPDATE comercial.CampaniaJabaPlan SET estado='DEVUELTA',fecha_devolucion=SYSUTCDATETIME(),version=version+1,
      usuario_modifica_id=@usuario WHERE campania_jaba_plan_id=@asignacion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaRecepcion',@id,'PESAR_JABA',
      (SELECT @part participacionId,@numero numero,@peso pesoBrutoKg,@descuento descuentoKg,@calibre calibreId,@observacion observacion FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @numero numero,@registradas devueltas,@asignadas asignadas,
    (SELECT version FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_recepcion_id=@id) version,
    (SELECT COALESCE(SUM(peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion) pesoBrutoKg,
    (SELECT COALESCE(SUM(peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion) pesoNetoKg
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'RECEPCION_JABA',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Jaba registrada.',@cCodigoRespuesta='RECEPCION_JABA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_REGISTRO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo registrar la jaba.' END;
 END CATCH;
END;
GO
