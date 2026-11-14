-- DESCO APAPPSS. Edición de calibres en un solo formulario y observación por jaba.
-- No altera migraciones V622 / V627 ni registros previos.
IF COL_LENGTH(N'comercial.CampaniaCalibre',N'activo') IS NULL
  ALTER TABLE comercial.CampaniaCalibre ADD activo BIT NOT NULL CONSTRAINT DF_CampaniaCalibre_Activo DEFAULT(1);
GO
IF COL_LENGTH(N'comercial.CampaniaJabaRecepcion',N'observacion') IS NULL
  ALTER TABLE comercial.CampaniaJabaRecepcion ADD observacion NVARCHAR(400) NULL;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaVentaProceso_Sel_Detalle
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la recepción.',@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),@uot BIGINT,
   @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
   @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52001,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_VER',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_VER')<>1
    OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1
    THROW 52002,N'No tiene acceso al proceso de venta.',1;
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.nombre,C.codigo,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,
    C.estado_proceso estadoProceso,C.descuento_jaba_kg descuentoJabaKg,
    CAST(CASE WHEN C.estado_proceso IN('ACTIVA','PLANIFICACION') AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin THEN 1 ELSE 0 END AS BIT) vigente,
    JSON_QUERY((SELECT G.campania_calibre_id calibreId,G.variedad_palta_id variedadPaltaId,G.calibre,
        G.gramos_desde gramosDesde,G.gramos_hasta gramosHasta,G.precio_kg precioKg,G.version
       FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.activo=1 ORDER BY G.variedad_palta_id,G.gramos_desde FOR JSON PATH)) calibres,
    JSON_QUERY((SELECT P.participacion_campania_socio_id participacionId,P.socio_asociacion_id socioAsociacionId,
       PE.numero_documento documento,
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,J.cantidad asignadas,J.estado estadoJabas,
       (SELECT COUNT_BIG(*) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) devueltas,
       (SELECT COALESCE(SUM(R.peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoBrutoKg,
       (SELECT COALESCE(SUM(R.descuento_jaba_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) descuentoTotalKg,
       (SELECT COALESCE(SUM(R.peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=J.campania_jaba_plan_id) pesoNetoKg
      FROM comercial.ParticipacionCampaniaSocio P
      JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
      JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=P.socio_asociacion_id
      JOIN org.Socio SO ON SO.socio_id=SA.socio_id
      JOIN org.Persona PE ON PE.persona_id=SO.socio_id
      WHERE P.campania_venta_id=@camp AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.cantidad>=1
      ORDER BY P.participacion_campania_socio_id FOR JSON PATH)) socios
   FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='RECEPCION_LISTADO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_LISTADO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo consultar la recepción.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaRecepcion_Sel_Pagina
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar las jabas.',@cCodigoRespuesta='RECEPCION_PAGINA_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
   @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
   @pagina INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.pagina')),1),
   @tamano INT=COALESCE(TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.filtros.tamano')),25),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@plan BIGINT,@cantidad INT;
 BEGIN TRY
  IF @pagina<1 OR @tamano NOT BETWEEN 1 AND 100 OR @part IS NULL THROW 52003,N'Paginación inválida.',1;
  SELECT @uot=C.uot_id,@plan=J.campania_jaba_plan_id,@cantidad=J.cantidad FROM comercial.CampaniaVenta C
   JOIN comercial.ParticipacionCampaniaSocio P ON P.campania_venta_id=C.campania_venta_id AND P.participacion_campania_socio_id=@part AND P.estado=1
   JOIN comercial.CampaniaJabaPlan J ON J.participacion_campania_socio_id=P.participacion_campania_socio_id AND J.activo=1
   WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @plan IS NULL THROW 52004,N'No se encontró la asignación de jabas.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_LISTAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_LISTAR')<>1 THROW 52005,N'Acceso no autorizado.',1;
  DECLARE @desde BIGINT=(CONVERT(BIGINT,@pagina)-1)*@tamano+1,@hasta BIGINT=CONVERT(BIGINT,@pagina)*@tamano;
  SET @cDatos=(SELECT @part participacionId,@cantidad asignadas,@pagina pagina,@tamano tamano,
    JSON_QUERY((SELECT R.numero_jaba numero,R.peso_bruto_kg pesoBrutoKg,R.descuento_jaba_kg descuentoKg,
        R.peso_neto_kg pesoNetoKg,R.campania_calibre_id calibreId,R.observacion,R.version
      FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=@plan
      AND R.numero_jaba BETWEEN @desde AND @hasta ORDER BY R.numero_jaba FOR JSON PATH)) registros
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Consulta realizada.',@cCodigoRespuesta='RECEPCION_PAGINA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_PAGINA_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudieron consultar las jabas.' END;
 END CATCH;
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
  IF @asignacion IS NULL OR @estado NOT IN('ENTREGADA','DEVUELTA') OR @numero>@asignadas
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

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaRecepcion_Upd_Corregir
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
  @motivo NVARCHAR(500)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@asignacion BIGINT,@asignadas INT,@estado VARCHAR(20),@descuento DECIMAL(9,3),@registradas INT,@id BIGINT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),@appLock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
  @pesoAnterior DECIMAL(12,3),@descuentoAnterior DECIMAL(9,3),@calibreAnterior BIGINT,@observacionAnterior NVARCHAR(400);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @part IS NULL OR @numero IS NULL OR @numero<1
     OR @peso IS NULL OR @peso<0 OR @peso>999999 OR LEN(COALESCE(JSON_VALUE(@cJson,'$.datos.observacion'),N''))>400 OR (@peso=0 AND @calibre IS NOT NULL)
    THROW 52010,N'Ingrese un peso no negativo; una jaba vacía debe tener peso 0.',1;
  IF @version IS NULL OR @version<1 OR @motivo IS NULL OR LEN(@motivo)<10 OR LEN(@motivo)>500
    THROW 52020,N'La corrección requiere una versión y un motivo de al menos 10 caracteres.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52011,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
    THROW 52012,N'No tiene permiso para registrar recepciones.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'RECEPCION_JABA_CORREGIR|',@camp,'|',@part,'|',@numero,'|',JSON_QUERY(@cJson,'$.datos')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52013,N'Otra operación está modificando las jabas.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
   IF @prev<>@hash THROW 52014,N'Esta solicitud se utilizó con otros datos.',1;
   SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Registro procesado anteriormente.',@cCodigoRespuesta='RECEPCION_JABA_CORREGIDA_OK',@nHttpRespuesta=200;
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
  IF @asignacion IS NULL OR @estado NOT IN('ENTREGADA','DEVUELTA') OR @numero>@asignadas
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
  SELECT @id=campania_jaba_recepcion_id,@pesoAnterior=peso_bruto_kg,
    @descuentoAnterior=descuento_jaba_kg,@calibreAnterior=campania_calibre_id,@observacionAnterior=observacion
   FROM comercial.CampaniaJabaRecepcion WITH(UPDLOCK,HOLDLOCK)
   WHERE campania_jaba_plan_id=@asignacion AND numero_jaba=@numero;
  IF @id IS NULL THROW 52020,N'Esta jaba aún no tiene un pesaje registrado.',1;
  IF @pesoAnterior=@peso AND @descuentoAnterior=@descuento
     AND ((@calibreAnterior=@calibre) OR (@calibreAnterior IS NULL AND @calibre IS NULL))
     AND COALESCE(@observacionAnterior,N'')=COALESCE(@observacion,N'')
    THROW 52020,N'No hay cambios que guardar.',1;
  UPDATE comercial.CampaniaJabaRecepcion SET peso_bruto_kg=@peso,descuento_jaba_kg=@descuento,
    campania_calibre_id=@calibre,observacion=@observacion,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME(),version=version+1
   WHERE campania_jaba_recepcion_id=@id AND version=@version;
  IF @@ROWCOUNT<>1 THROW 52019,N'El pesaje fue modificado por otro usuario; actualice la página.',1;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaRecepcion',@id,'CORREGIR_PESAJE',
      (SELECT @part participacionId,@numero numero,@pesoAnterior pesoAnteriorKg,
        @descuentoAnterior descuentoAnteriorKg,@calibreAnterior calibreAnteriorId,
        @peso pesoNuevoKg,@descuento descuentoNuevoKg,@calibre calibreNuevoId,
        @observacionAnterior observacionAnterior,@observacion observacionNueva,
        @motivo motivo,@version versionAnterior FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@usuario);
  SET @cDatos=(SELECT @numero numero,@registradas devueltas,@asignadas asignadas,
    (SELECT version FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_recepcion_id=@id) version,
    (SELECT COALESCE(SUM(peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion) pesoBrutoKg,
    (SELECT COALESCE(SUM(peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion) pesoNetoKg
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'RECEPCION_JABA_CORREGIR',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Pesaje corregido.',@cCodigoRespuesta='RECEPCION_JABA_CORREGIDA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_REGISTRO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo registrar la jaba.' END;
 END CATCH;
END;
GO

-- Una sola operación transaccional para los calibres editados en la campaña.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaCalibre_Upd_Lista
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudieron guardar los calibres.',
        @cCodigoRespuesta='CALIBRES_EDICION_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
   @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
   @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
   @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
   @acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT,
   @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
   @retirados INT=0,@agregados INT=0,@versionados INT=0;
 DECLARE @lineas TABLE(
   fila INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
   calibre_id BIGINT NULL,version INT NULL,variedad SMALLINT NULL,calibre VARCHAR(12) NULL,
   desde INT NULL,hasta INT NULL,precio DECIMAL(14,4) NULL
 );
 DECLARE @nuevosPrecios TABLE(calibre_id BIGINT NOT NULL,version INT NOT NULL,precio DECIMAL(14,4) NOT NULL);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR JSON_QUERY(@cJson,'$.datos.calibres') IS NULL
    THROW 52101,N'La información de calibres está incompleta.',1;
  INSERT @lineas(calibre_id,version,variedad,calibre,desde,hasta,precio)
    SELECT calibreId,version,variedadPaltaId,calibre,gramosDesde,gramosHasta,precioKg
    FROM OPENJSON(@cJson,'$.datos.calibres')
    WITH(calibreId BIGINT '$.calibreId',version INT '$.version',variedadPaltaId SMALLINT '$.variedadPaltaId',
         calibre VARCHAR(12) '$.calibre',gramosDesde INT '$.gramosDesde',gramosHasta INT '$.gramosHasta',precioKg DECIMAL(14,4) '$.precioKg');
  IF (SELECT COUNT(1) FROM @lineas) NOT BETWEEN 1 AND 20
    THROW 52102,N'La campaña requiere entre 1 y 20 calibres.',1;
  IF EXISTS(SELECT 1 FROM @lineas WHERE variedad IS NULL OR calibre NOT IN('PRIMERA','SEGUNDA','DESCARTE')
    OR desde IS NULL OR desde<0 OR (hasta IS NOT NULL AND hasta<desde) OR precio IS NULL OR precio<=0
    OR (calibre_id IS NOT NULL AND (version IS NULL OR version<1)))
    THROW 52103,N'Revise variedad, calibre, rango en gramos y precio.',1;
  IF EXISTS(SELECT 1 FROM @lineas A JOIN @lineas B ON A.fila<B.fila AND A.variedad=B.variedad
    AND (A.calibre=B.calibre OR (A.desde<=COALESCE(B.hasta,2147483647) AND B.desde<=COALESCE(A.hasta,2147483647))))
    THROW 52104,N'Hay calibres duplicados o rangos superpuestos.',1;
  IF EXISTS(SELECT calibre_id FROM @lineas WHERE calibre_id IS NOT NULL GROUP BY calibre_id HAVING COUNT(1)>1)
    THROW 52105,N'Hay calibres repetidos en la lista.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52106,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1
    THROW 52107,N'No tiene permiso para editar la campaña.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'CAMPANIA_CALIBRES_LISTA|',@camp,N'|',JSON_QUERY(@cJson,'$.datos.calibres')));
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52108,N'La campaña está siendo modificada.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
   WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52109,N'La solicitud ya fue utilizada con otros datos.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Cambios guardados anteriormente.',
      @cCodigoRespuesta='CALIBRES_EDICION_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA'))
    THROW 52110,N'La campaña ya no permite cambios.',1;
  IF EXISTS(SELECT 1 FROM @lineas L LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=L.variedad AND V.estado=1 WHERE V.variedad_palta_id IS NULL)
    THROW 52111,N'Una de las variedades no está disponible.',1;
  IF EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id IS NOT NULL AND NOT EXISTS(
    SELECT 1 FROM comercial.CampaniaCalibre G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.campania_calibre_id=L.calibre_id AND G.campania_venta_id=@camp AND G.activo=1
      AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre AND G.gramos_desde=L.desde
      AND (G.gramos_hasta=L.hasta OR G.gramos_hasta IS NULL AND L.hasta IS NULL) AND G.version=L.version))
    THROW 52112,N'Algún calibre ha cambiado. Actualice la campaña.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G WITH(UPDLOCK,HOLDLOCK)
    WHERE G.campania_venta_id=@camp AND G.activo=1
      AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id)
      AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_calibre_id=G.campania_calibre_id))
    THROW 52113,N'No se puede quitar un calibre que tiene pesajes registrados.',1;
  IF EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id IS NULL
     AND EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G
       WHERE G.campania_venta_id=@camp AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre
       AND G.activo=0 AND EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_calibre_id=G.campania_calibre_id)))
    THROW 52114,N'No se puede reutilizar un calibre que conserva pesajes.',1;
  IF EXISTS(SELECT 1 FROM @lineas WHERE calibre_id IS NULL)
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1
    THROW 52115,N'No tiene permiso para agregar calibres.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.activo=1
      AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id))
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_RETIRAR')<>1
    THROW 52116,N'No tiene permiso para quitar calibres.',1;
  IF EXISTS(SELECT 1 FROM @lineas L JOIN comercial.CampaniaCalibre G ON G.campania_calibre_id=L.calibre_id
      WHERE G.precio_kg<>L.precio)
    AND seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_EDITAR')<>1
    THROW 52117,N'No tiene permiso para cambiar precios.',1;

  UPDATE G SET activo=0 FROM comercial.CampaniaCalibre G
   WHERE G.campania_venta_id=@camp AND G.activo=1
     AND NOT EXISTS(SELECT 1 FROM @lineas L WHERE L.calibre_id=G.campania_calibre_id);
  SET @retirados=@@ROWCOUNT;

  UPDATE G SET activo=1,gramos_desde=L.desde,gramos_hasta=L.hasta,precio_kg=L.precio,version=G.version+1
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    FROM comercial.CampaniaCalibre G JOIN @lineas L ON L.calibre_id IS NULL AND L.variedad=G.variedad_palta_id
      AND L.calibre=G.calibre WHERE G.campania_venta_id=@camp AND G.activo=0;
  SET @agregados=@@ROWCOUNT;

  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id,activo)
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    SELECT @camp,L.variedad,L.calibre,L.desde,L.hasta,L.precio,@usuario,1
    FROM @lineas L WHERE L.calibre_id IS NULL AND NOT EXISTS(
      SELECT 1 FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp AND G.variedad_palta_id=L.variedad AND G.calibre=L.calibre);
  SET @agregados=@agregados+@@ROWCOUNT;

  UPDATE G SET precio_kg=L.precio,version=G.version+1
    OUTPUT inserted.campania_calibre_id,inserted.version,inserted.precio_kg INTO @nuevosPrecios
    FROM comercial.CampaniaCalibre G JOIN @lineas L ON L.calibre_id=G.campania_calibre_id
    WHERE G.campania_venta_id=@camp AND G.activo=1 AND G.precio_kg<>L.precio;
  SET @versionados=@@ROWCOUNT;
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
    SELECT C.calibre_id,C.version,C.precio,@usuario FROM @nuevosPrecios C;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaCalibre',@camp,'EDITAR_CALIBRES',
    (SELECT @retirados retirados,@agregados agregados,@versionados preciosActualizados FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaId,
    (SELECT COUNT(1) FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp AND activo=1) calibres
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'CAMPANIA_CALIBRES_LISTA',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Calibres actualizados.',@cCodigoRespuesta='CALIBRES_EDICION_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CALIBRES_EDICION_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52101 AND 52199 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52101 AND 52199 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudieron guardar los calibres.' END;
 END CATCH;
END;
GO
