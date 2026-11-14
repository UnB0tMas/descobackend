-- DESCO / APAPPSS: PAs separados por responsabilidad. Ninguna migración anterior se modifica.
-- La creación conjunta de campaña + precios + cupo es una única transacción de negocio.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Ins_Crear
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo crear la campaña.',@cCodigoRespuesta='CAMPANIA_PLAN_INVALIDA',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@uot BIGINT,@camp BIGINT,@appLock INT,
  @asociacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.asociacionId')),
  @comprador BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.empresaCompradoraId')),
  @nombre NVARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
  @inicio DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaInicio')),
  @fin DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaFin')),
  @observacion NVARCHAR(400)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @cupo INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cupoJabas')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@codigo VARCHAR(40),@fecha DATETIME2(0)=SYSUTCDATETIME();
 DECLARE @precios TABLE(variedad SMALLINT NOT NULL,condicion BIGINT NOT NULL,precio DECIMAL(14,4) NOT NULL,
  PRIMARY KEY(variedad,condicion));
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @asociacion IS NULL OR @comprador IS NULL OR @nombre IS NULL
    OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL OR @fin<@inicio OR @asociacion=@comprador
    OR (@cupo IS NOT NULL AND @cupo NOT BETWEEN 1 AND 100000) OR LEN(COALESCE(@observacion,N''))>400
    THROW 51400,N'Complete los datos, fechas y cupo de campaña correctamente.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 THROW 51401,N'No tiene acceso a campañas.',1;
  SELECT @uot=A.uot_id FROM org.Asociacion A JOIN org.Empresa E ON E.empresa_id=A.asociacion_id AND E.estado=1
   WHERE A.asociacion_id=@asociacion AND A.estado=1;
  IF @uot IS NULL OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_CREAR')<>1
     OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1
    THROW 51401,N'Sin autorización territorial para crear campaña y registrar precios.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1
     AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,@fecha))
     AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,@fecha)))
    THROW 51402,N'La asociación no tiene un convenio APAPPSS vigente.',1;
  IF NOT EXISTS(SELECT 1 FROM org.Empresa E JOIN org.ConvenioUOTOrganizacion CU
    ON CU.empresa_id=E.empresa_id AND CU.uot_id=@uot AND CU.estado=1 AND CU.fecha_fin IS NULL
    WHERE E.empresa_id=@comprador AND E.estado=1)
    THROW 51403,N'El comprador no pertenece al convenio activo.',1;
  IF JSON_QUERY(@cJson,'$.datos.precios') IS NULL OR
   (SELECT COUNT(1) FROM OPENJSON(@cJson,'$.datos.precios')) NOT BETWEEN 1 AND 20
    THROW 51404,N'Registre entre una y veinte variedades con sus precios.',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.precios') WITH
    (variedad SMALLINT '$.variedadPaltaId',condicion BIGINT '$.condicionComercialId',precio DECIMAL(14,4) '$.precio')
    WHERE variedad IS NULL OR condicion IS NULL OR precio IS NULL OR precio<=0)
    THROW 51405,N'Cada variedad requiere condición y precio positivo.',1;
  IF EXISTS(SELECT variedad FROM OPENJSON(@cJson,'$.datos.precios') WITH(variedad SMALLINT '$.variedadPaltaId')
    GROUP BY variedad HAVING COUNT(1)>1)
    THROW 51406,N'Una variedad debe aparecer una sola vez al crear la campaña.',1;
  INSERT INTO @precios(variedad,condicion,precio)
   SELECT variedad,condicion,precio FROM OPENJSON(@cJson,'$.datos.precios') WITH
   (variedad SMALLINT '$.variedadPaltaId',condicion BIGINT '$.condicionComercialId',precio DECIMAL(14,4) '$.precio');
  IF EXISTS(SELECT 1 FROM @precios P LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad AND V.estado=1
    LEFT JOIN comercial.CondicionComercial C ON C.condicion_comercial_id=P.condicion AND C.estado=1
    WHERE V.variedad_palta_id IS NULL OR C.condicion_comercial_id IS NULL)
    THROW 51407,N'La variedad o condición seleccionada no está vigente.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'CAMPANIA_PLAN|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 51408,N'Existe otra operación comercial en curso.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 51409,N'La clave de solicitud pertenece a otro cambio.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Campaña registrada anteriormente.',@cCodigoRespuesta='CAMPANIA_PLAN_CREADA',@nHttpRespuesta=200;
   COMMIT TRANSACTION; RETURN;
  END;
  SET @codigo=CONCAT('CAM-',CONVERT(VARCHAR(4),YEAR(@inicio)),'-',UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),12)));
  INSERT comercial.CampaniaVenta(asociacion_id,empresa_compradora_id,codigo,nombre,fecha_inicio,fecha_fin,estado_proceso,observacion,estado,uot_id)
   VALUES(@asociacion,@comprador,@codigo,@nombre,@inicio,@fin,'PLANIFICACION',@observacion,1,@uot);
  SET @camp=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.PrecioComercial(campania_venta_id,operativo_venta_id,variedad_palta_id,condicion_comercial_id,
    precio,moneda,unidad_medida,fecha_vigencia_desde,fecha_vigencia_hasta,version,estado)
   SELECT @camp,NULL,P.variedad,P.condicion,P.precio,'PEN','KG',CONVERT(DATETIME2(0),@inicio),NULL,1,1 FROM @precios P;
  IF @cupo IS NOT NULL INSERT comercial.CampaniaControlE4(campania_venta_id,cupo_jabas,tara_kg,usuario_id)
   VALUES(@camp,@cupo,0,@usuario);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaVenta',@camp,'CREAR_PLAN',(SELECT COUNT(*) precios,@cupo cupoJabas FROM @precios FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaVentaId,(SELECT COUNT(1) FROM @precios) preciosCreados,@cupo cupoJabas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
   VALUES(@usuario,@clave,'CREAR_CAMPANIA_PLAN',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Campaña y precios registrados.',@cCodigoRespuesta='CAMPANIA_PLAN_CREADA',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SET @cDatos=NULL;SET @bResultado=0;SET @cCodigoRespuesta='CAMPANIA_PLAN_ERROR';
  SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END;
  SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300)
    ELSE N'No se pudo registrar la campaña y sus precios.' END;
 END CATCH;
END;
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
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,K.cupo_jabas cupoJabas,K.tara_kg taraKg,
   S.existencia_certificada stockFisico,
   (SELECT COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0) FROM comercial.CampaniaJabaPlan J
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
     J.cantidad cantidadJabas,J.estado estadoJabas,J.version versionJabas
     FROM comercial.ParticipacionCampaniaSocio P JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
     JOIN org.Socio SO ON SO.socio_id=SA.socio_id
     JOIN org.Persona PE ON PE.persona_id=SO.socio_id
     LEFT JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
     WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO'
     ORDER BY PE.apellido_paterno,PE.nombres,P.participacion_campania_socio_id FOR JSON PATH)) participantes
   FROM comercial.CampaniaVenta C LEFT JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id
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
 @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
 @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
 @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
 @appLock INT,@hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@id BIGINT,@actual INT,@estado VARCHAR(20),
 @cupo INT,@ocupadas BIGINT,@reservadas BIGINT,@nuevaVersion BIGINT,@fecha DATETIME2(0)=SYSUTCDATETIME();
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
  IF @cantidad=0
  BEGIN
   IF @id IS NULL OR @estado<>'PENDIENTE_RECOJO'
     THROW 51440,N'Solo puede quitar asignaciones pendientes de recojo.',1;
   UPDATE comercial.CampaniaJabaPlan SET activo=0,version=version+1,usuario_modifica_id=@usuario
    WHERE campania_jaba_plan_id=@id AND activo=1;
  END
  ELSE IF @id IS NULL
  BEGIN
   INSERT comercial.CampaniaJabaPlan(participacion_campania_socio_id,cantidad,estado,usuario_registro_id)
    VALUES(@participacion,@cantidad,'PENDIENTE_RECOJO',@usuario);
   SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
   IF @estado<>'PENDIENTE_RECOJO' OR (@actual<>@cantidad AND @estado<>'PENDIENTE_RECOJO')
    THROW 51437,N'La entrega no permite modificar cantidades.',1;
   UPDATE comercial.CampaniaJabaPlan SET cantidad=@cantidad,activo=1,version=version+1,usuario_modifica_id=@usuario
    WHERE campania_jaba_plan_id=@id;
  END;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaPlan',@id,CASE WHEN @cantidad=0 THEN 'ANULAR_ASIGNACION' ELSE 'AJUSTAR_ASIGNACION' END,
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
