-- DESCO / APAPPSS: proceso de venta por jaba, calibres y descuento opcional.
-- La recepción no genera pagos ni liquidaciones; conserva el peso real y la clasificación.
IF COL_LENGTH(N'comercial.CampaniaVenta',N'descuento_jaba_kg') IS NULL
  ALTER TABLE comercial.CampaniaVenta ADD descuento_jaba_kg DECIMAL(9,3) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'comercial.CampaniaVenta') AND name=N'CK_CampaniaVenta_DescuentoJaba')
  ALTER TABLE comercial.CampaniaVenta WITH CHECK ADD CONSTRAINT CK_CampaniaVenta_DescuentoJaba CHECK (descuento_jaba_kg IS NULL OR descuento_jaba_kg BETWEEN 0 AND 9.999);
GO
IF OBJECT_ID(N'comercial.CampaniaCalibre',N'U') IS NULL
BEGIN
  CREATE TABLE comercial.CampaniaCalibre (
    campania_calibre_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaCalibre PRIMARY KEY,
    campania_venta_id BIGINT NOT NULL REFERENCES comercial.CampaniaVenta(campania_venta_id),
    variedad_palta_id SMALLINT NOT NULL REFERENCES prod.VariedadPalta(variedad_palta_id),
    calibre VARCHAR(12) NOT NULL,
    gramos_desde INT NOT NULL,
    gramos_hasta INT NULL,
    precio_kg DECIMAL(14,4) NOT NULL,
    version INT NOT NULL CONSTRAINT DF_CampaniaCalibre_Version DEFAULT(1),
    usuario_registro_id BIGINT NULL,
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaCalibre_Registro DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT UQ_CampaniaCalibre_CampaniaVariedadCalibre UNIQUE(campania_venta_id,variedad_palta_id,calibre),
    CONSTRAINT CK_CampaniaCalibre_Tipo CHECK(calibre IN('PRIMERA','SEGUNDA','DESCARTE')),
    CONSTRAINT CK_CampaniaCalibre_Gramos CHECK(gramos_desde>=0 AND (gramos_hasta IS NULL OR gramos_hasta>=gramos_desde)),
    CONSTRAINT CK_CampaniaCalibre_Precio CHECK(precio_kg>0)
  );
END;
GO
IF OBJECT_ID(N'comercial.CampaniaCalibrePrecioVersion',N'U') IS NULL
BEGIN
 CREATE TABLE comercial.CampaniaCalibrePrecioVersion(
  campania_calibre_precio_version_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaCalibrePrecioVersion PRIMARY KEY,
  campania_calibre_id BIGINT NOT NULL REFERENCES comercial.CampaniaCalibre(campania_calibre_id),
  version INT NOT NULL,
  precio_kg DECIMAL(14,4) NOT NULL,
  usuario_id BIGINT NULL,
  fecha DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaCalibrePrecioVersion_Fecha DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT UQ_CampaniaCalibrePrecioVersion UNIQUE(campania_calibre_id,version),
  CONSTRAINT CK_CampaniaCalibrePrecioVersion_Precio CHECK(precio_kg>0)
 );
END;
GO
IF OBJECT_ID(N'comercial.CampaniaJabaRecepcion',N'U') IS NULL
BEGIN
 CREATE TABLE comercial.CampaniaJabaRecepcion(
  campania_jaba_recepcion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CampaniaJabaRecepcion PRIMARY KEY,
  campania_jaba_plan_id BIGINT NOT NULL REFERENCES comercial.CampaniaJabaPlan(campania_jaba_plan_id),
  numero_jaba INT NOT NULL,
  peso_bruto_kg DECIMAL(12,3) NOT NULL,
  descuento_jaba_kg DECIMAL(9,3) NOT NULL,
  peso_neto_kg AS CONVERT(DECIMAL(12,3),CASE WHEN peso_bruto_kg=0 THEN 0 ELSE peso_bruto_kg-descuento_jaba_kg END) PERSISTED,
  campania_calibre_id BIGINT NULL REFERENCES comercial.CampaniaCalibre(campania_calibre_id),
  usuario_registro_id BIGINT NULL,
  fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_CampaniaJabaRecepcion_Fecha DEFAULT(SYSUTCDATETIME()),
  usuario_modifica_id BIGINT NULL,
  fecha_modifica DATETIME2(0) NULL,
  version INT NOT NULL CONSTRAINT DF_CampaniaJabaRecepcion_Version DEFAULT(1),
  CONSTRAINT UQ_CampaniaJabaRecepcion_PlanNumero UNIQUE(campania_jaba_plan_id,numero_jaba),
  CONSTRAINT CK_CampaniaJabaRecepcion_Numero CHECK(numero_jaba>=1),
  CONSTRAINT CK_CampaniaJabaRecepcion_Pesos CHECK(peso_bruto_kg>=0 AND descuento_jaba_kg>=0
      AND (peso_bruto_kg=0 AND descuento_jaba_kg=0 AND campania_calibre_id IS NULL
          OR peso_bruto_kg>0 AND peso_bruto_kg>=descuento_jaba_kg AND campania_calibre_id IS NOT NULL))
 );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.CampaniaJabaRecepcion') AND name=N'IX_CampaniaJabaRecepcion_Calibre')
 CREATE INDEX IX_CampaniaJabaRecepcion_Calibre ON comercial.CampaniaJabaRecepcion(campania_calibre_id) INCLUDE(peso_bruto_kg,descuento_jaba_kg);
GO

-- La consulta tiene responsabilidad única: ficha de campaña, calibres y socios con sus acumulados.
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
       FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp ORDER BY G.variedad_palta_id,G.gramos_desde FOR JSON PATH)) calibres,
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

-- Paginación sin generar 100 000 filas vacías: sólo devuelve números efectivamente registrados.
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
        R.peso_neto_kg pesoNetoKg,R.campania_calibre_id calibreId,R.version
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

-- El pesaje guarda una jaba. Confirmar la última implica marcar la devolución total en la misma transacción.
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
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@asignacion BIGINT,@asignadas INT,@estado VARCHAR(20),@descuento DECIMAL(9,3),@registradas INT,@id BIGINT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),@appLock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @part IS NULL OR @numero IS NULL OR @numero<1
     OR @peso IS NULL OR @peso<0 OR @peso>999999 OR (@peso=0 AND @calibre IS NOT NULL)
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
    IF @calibre IS NULL AND (SELECT COUNT(1) FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp)=1
       SELECT @calibre=campania_calibre_id FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp;
    IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_calibre_id=@calibre AND campania_venta_id=@camp)
       THROW 52018,N'Seleccione un calibre y variedad registrados en esta campaña.',1;
  END;
  IF @peso=0 SET @descuento=0;
  SELECT @id=campania_jaba_recepcion_id FROM comercial.CampaniaJabaRecepcion WITH(UPDLOCK,HOLDLOCK)
   WHERE campania_jaba_plan_id=@asignacion AND numero_jaba=@numero;
  IF @id IS NULL
  BEGIN
    IF @version IS NOT NULL THROW 52019,N'La jaba fue modificada; actualice el listado.',1;
    INSERT comercial.CampaniaJabaRecepcion(campania_jaba_plan_id,numero_jaba,peso_bruto_kg,descuento_jaba_kg,campania_calibre_id,usuario_registro_id)
      VALUES(@asignacion,@numero,@peso,@descuento,@calibre,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  END
  ELSE
  BEGIN
    UPDATE comercial.CampaniaJabaRecepcion SET peso_bruto_kg=@peso,descuento_jaba_kg=@descuento,
      campania_calibre_id=@calibre,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME(),version=version+1
     WHERE campania_jaba_recepcion_id=@id AND version=@version;
    IF @@ROWCOUNT<>1 THROW 52019,N'La jaba fue modificada; actualice el listado.',1;
  END;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion;
  IF @registradas=@asignadas AND @estado='ENTREGADA'
    UPDATE comercial.CampaniaJabaPlan SET estado='DEVUELTA',fecha_devolucion=SYSUTCDATETIME(),version=version+1,
      usuario_modifica_id=@usuario WHERE campania_jaba_plan_id=@asignacion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaRecepcion',@id,'PESAR_JABA',
      (SELECT @part participacionId,@numero numero,@peso pesoBrutoKg,@descuento descuentoKg,@calibre calibreId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
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

-- Configurar descuento independiente. Nunca se altera la tara después de iniciar pesajes.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaDescuentoJaba_Upd_Configurar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo guardar el descuento.',@cCodigoRespuesta='DESCUENTO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @valor DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT;
 BEGIN TRY
  IF @valor IS NOT NULL AND (@valor<0 OR @valor>9.999) THROW 52021,N'El descuento debe estar entre 0 y 9.999 kg.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52022,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_EDITAR')<>1 THROW 52023,N'Sin permiso para editar campañas.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52024,N'La campaña está siendo modificada.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaJabaRecepcion R
    JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp) THROW 52025,N'No puede cambiar el descuento después de registrar pesajes.',1;
  UPDATE comercial.CampaniaVenta SET descuento_jaba_kg=@valor WHERE campania_venta_id=@camp AND estado_proceso IN('PLANIFICACION','ACTIVA');
  IF @@ROWCOUNT<>1 THROW 52026,N'La campaña no admite modificaciones.',1;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaVenta',@camp,'CONFIGURAR_DESCUENTO',(SELECT @valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @camp campaniaId,@valor descuentoJabaKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  SELECT @bResultado=1,@cMensaje=N'Descuento actualizado.',@cCodigoRespuesta='DESCUENTO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='DESCUENTO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo guardar el descuento.' END;
 END CATCH;
END;
GO

-- Agregar un calibre y su precio inicial; el precio histórico de otras variedades no se modifica.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaCalibre_Ins_Registro
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo agregar el calibre.',@cCodigoRespuesta='CALIBRE_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @variedad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.variedadPaltaId')),
  @calibre VARCHAR(12)=UPPER(JSON_VALUE(@cJson,'$.datos.calibre')),
  @desde INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.gramosDesde')),
  @hasta INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.gramosHasta')),
  @precio DECIMAL(14,4)=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioKg')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT,@id BIGINT;
 BEGIN TRY
  IF @calibre NOT IN('PRIMERA','SEGUNDA','DESCARTE') OR @desde IS NULL OR @desde<0
   OR (@hasta IS NOT NULL AND @hasta<@desde) OR @precio IS NULL OR @precio<=0 OR @variedad IS NULL
   THROW 52031,N'Indique variedad, calibre, rango en gramos y precio positivo.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52032,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PRECIOS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1 THROW 52033,N'Sin permiso para registrar calibres.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52034,N'La campaña está siendo modificada.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA'))
     THROW 52035,N'La campaña ya no permite registrar calibres.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.VariedadPalta WHERE variedad_palta_id=@variedad AND estado=1)
     THROW 52036,N'La variedad no existe.',1;
  IF EXISTS(SELECT 1 FROM comercial.CampaniaCalibre X WITH(UPDLOCK,HOLDLOCK)
   WHERE X.campania_venta_id=@camp AND X.variedad_palta_id=@variedad
    AND (X.calibre=@calibre OR (@desde<=COALESCE(X.gramos_hasta,2147483647)
      AND X.gramos_desde<=COALESCE(@hasta,2147483647))))
    THROW 52037,N'Existe un calibre duplicado o con rango de gramos superpuesto.',1;
  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id)
   VALUES(@camp,@variedad,@calibre,@desde,@hasta,@precio,@usuario);
  SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
   VALUES(@id,1,@precio,@usuario);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaCalibre',@id,'CREAR_CALIBRE',
      (SELECT @variedad variedadPaltaId,@calibre calibre,@desde gramosDesde,@hasta gramosHasta,@precio precioKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @id calibreId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Calibre agregado.',@cCodigoRespuesta='CALIBRE_OK',@nHttpRespuesta=201;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CALIBRE_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo agregar el calibre.' END;
 END CATCH;
END;
GO

-- Cambiar precio de un calibre agrega nueva versión, sin modificar las recepciones históricas.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaCalibre_Upd_Precio
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo versionar el precio.',@cCodigoRespuesta='CALIBRE_PRECIO_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @id BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.calibreId')),
  @precio DECIMAL(14,4)=TRY_CONVERT(DECIMAL(14,4),JSON_VALUE(@cJson,'$.datos.precioKg')),
  @version INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.version')),
  @uot BIGINT,@usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),@appLock INT,@nuevaVersion INT;
 BEGIN TRY
  IF @precio IS NULL OR @precio<=0 OR @version IS NULL OR @version<1 THROW 52041,N'Indique un precio positivo y una versión válida.',1;
  SELECT @uot=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1;
  IF @uot IS NULL THROW 52042,N'La campaña no existe.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='PRECIOS_EDITAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_EDITAR')<>1 THROW 52043,N'Sin permiso para modificar precios.',1;
  BEGIN TRANSACTION;
  DECLARE @lockResource NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @appLock=sys.sp_getapplock @Resource=@lockResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @appLock<0 THROW 52044,N'La campaña está siendo modificada.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado=1 AND estado_proceso IN('PLANIFICACION','ACTIVA'))
    THROW 52045,N'La campaña ya no permite modificar precios.',1;
  UPDATE comercial.CampaniaCalibre SET precio_kg=@precio,version=version+1
   WHERE campania_calibre_id=@id AND campania_venta_id=@camp AND version=@version AND precio_kg<>@precio;
  IF @@ROWCOUNT<>1 THROW 52046,N'El precio no cambió o su versión está desactualizada.',1;
  SELECT @nuevaVersion=version FROM comercial.CampaniaCalibre WHERE campania_calibre_id=@id;
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
   VALUES(@id,@nuevaVersion,@precio,@usuario);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaCalibre',@id,'CAMBIAR_PRECIO_CALIBRE',
    (SELECT @nuevaVersion version,@precio precioKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  COMMIT TRANSACTION;
  SET @cDatos=(SELECT @id calibreId,@nuevaVersion version,@precio precioKg FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  SELECT @bResultado=1,@cMensaje=N'Precio versionado.',@cCodigoRespuesta='CALIBRE_PRECIO_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='CALIBRE_PRECIO_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo versionar el precio.' END;
 END CATCH;
END;
GO

-- Creación de campaña + calibres + precios base requiere atomicidad; conserva el PA vigente.
CREATE OR ALTER PROCEDURE comercial.PA_CampaniaPlan_Ins_Crear
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo crear la campaña.',@cCodigoRespuesta='CAMPANIA_PLAN_INVALIDA',@nHttpRespuesta=400;
 DECLARE @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.uotId')),@camp BIGINT,@appLock INT,
  @asociacion BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.asociacionId')),
  @comprador BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.compradorId')),
  @empresa BIGINT,
  @modalidad SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.datos.modalidadVentaId')),
  @condicion BIGINT,
  @nombre NVARCHAR(180)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.nombre')),N''),
  @inicio DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaInicio')),
  @fin DATE=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaFin')),
  @observacion NVARCHAR(400)=NULLIF(TRIM(JSON_VALUE(@cJson,'$.datos.observacion')),N''),
  @cupo INT=TRY_CONVERT(INT,JSON_VALUE(@cJson,'$.datos.cupoJabas')),
  @descuento DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@codigo VARCHAR(40),@fecha DATETIME2(0)=SYSUTCDATETIME(),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 DECLARE @precios TABLE(variedad SMALLINT NOT NULL PRIMARY KEY,precio DECIMAL(14,4) NOT NULL);
 DECLARE @calibres TABLE(indice INT IDENTITY(1,1) PRIMARY KEY,variedad SMALLINT NOT NULL,calibre VARCHAR(12) NOT NULL,
   gramos_desde INT NOT NULL,gramos_hasta INT NULL,precio DECIMAL(14,4) NOT NULL);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @uot IS NULL OR @asociacion IS NULL OR @comprador IS NULL OR @modalidad IS NULL OR @nombre IS NULL
    OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL OR @inicio<@hoy OR @fin<@hoy OR @fin<@inicio
    OR (@cupo IS NOT NULL AND @cupo NOT BETWEEN 1 AND 100000) OR (@descuento IS NOT NULL AND @descuento NOT BETWEEN 0 AND 9.999)
    OR LEN(COALESCE(@observacion,N''))>400
    THROW 51400,N'Complete los datos, fechas y cupo de campaña correctamente.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 THROW 51401,N'No tiene acceso a campañas.',1;
  -- La UOT se recibe del contexto seleccionado y se valida contra el convenio, no contra el dueño legacy de org.Asociacion.
  IF seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'CAMPANIAS_CREAR')<>1
     OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'PRECIOS_CREAR')<>1
    THROW 51401,N'Sin autorización territorial para crear campaña y registrar precios.',1;
  IF NOT EXISTS(SELECT 1 FROM org.ConvenioUOTOrganizacion CU
    JOIN org.Empresa AE ON AE.empresa_id=CU.empresa_id AND AE.ruc='20602771394' AND AE.estado=1
    JOIN org.Asociacion A ON A.asociacion_id=AE.empresa_id AND A.asociacion_id=@asociacion AND A.estado=1
    JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
    JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND M.estado=1
    JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
    WHERE CU.uot_id=@uot AND CU.empresa_id=@asociacion AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
     AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=@hoy)
     AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=@hoy))
    THROW 51402,N'La UOT seleccionada no tiene un convenio vigente con APAPPSS.',1;
  SELECT @empresa=CASE WHEN B.tipo='EMPRESA' THEN B.empresa_id ELSE NULL END
  FROM comercial.CompradorAPAPPSS B
  LEFT JOIN org.Empresa E ON E.empresa_id=B.empresa_id
  LEFT JOIN org.Persona P ON P.persona_id=B.persona_id
  WHERE B.comprador_apappss_id=@comprador AND B.uot_id=@uot AND B.estado=1
    AND ((B.tipo='EMPRESA' AND E.empresa_id IS NOT NULL AND E.estado=1)
      OR (B.tipo='PERSONA' AND P.persona_id IS NOT NULL AND P.estado=1));
  IF @@ROWCOUNT<>1 OR (@empresa IS NOT NULL AND @empresa=@asociacion)
    THROW 51403,N'Seleccione un comprador registrado y activo en APAPPSS.',1;
  IF NOT EXISTS(SELECT 1 FROM comercial.ModalidadVenta WHERE modalidad_venta_id=@modalidad AND estado=1)
    THROW 51407,N'Seleccione una modalidad de venta válida.',1;
  SELECT @condicion=C.condicion_comercial_id FROM comercial.CondicionComercial C
   WHERE C.modalidad_venta_id=@modalidad
    AND C.codigo=CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),@modalidad)) AND C.estado=1;
  IF @condicion IS NULL THROW 51407,N'No se encontró la modalidad configurada para campañas.',1;
  IF JSON_QUERY(@cJson,'$.datos.precios') IS NULL OR
   (SELECT COUNT(1) FROM OPENJSON(@cJson,'$.datos.precios')) NOT BETWEEN 1 AND 20
    THROW 51404,N'Registre entre una y veinte variedades con sus precios.',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.precios') WITH
    (variedad SMALLINT '$.variedadPaltaId',precio DECIMAL(14,4) '$.precio')
    WHERE variedad IS NULL OR precio IS NULL OR precio<=0)
    THROW 51405,N'Cada variedad requiere precio positivo.',1;
  IF EXISTS(SELECT variedad FROM OPENJSON(@cJson,'$.datos.precios') WITH(variedad SMALLINT '$.variedadPaltaId')
    GROUP BY variedad HAVING COUNT(1)>1)
    THROW 51406,N'Una variedad debe aparecer una sola vez al crear la campaña.',1;
  INSERT INTO @precios(variedad,precio)
   SELECT variedad,precio FROM OPENJSON(@cJson,'$.datos.precios') WITH
   (variedad SMALLINT '$.variedadPaltaId',precio DECIMAL(14,4) '$.precio');
  IF EXISTS(SELECT 1 FROM @precios P LEFT JOIN prod.VariedadPalta V ON V.variedad_palta_id=P.variedad AND V.estado=1
    WHERE V.variedad_palta_id IS NULL)
    THROW 51407,N'La variedad seleccionada no está vigente.',1;
  IF JSON_QUERY(@cJson,'$.datos.calibres') IS NULL
    OR (SELECT COUNT(1) FROM OPENJSON(@cJson,'$.datos.calibres')) NOT BETWEEN 1 AND 60
    THROW 52051,N'Debe registrar entre 1 y 60 calibres con sus precios.',1;
  IF EXISTS(SELECT 1 FROM OPENJSON(@cJson,'$.datos.calibres') WITH(
      variedad SMALLINT '$.variedadPaltaId',calibre VARCHAR(12) '$.calibre',
      gramos_desde INT '$.gramosDesde',gramos_hasta INT '$.gramosHasta',precio DECIMAL(14,4) '$.precioKg') G
     WHERE G.variedad IS NULL OR G.calibre NOT IN('PRIMERA','SEGUNDA','DESCARTE') OR G.gramos_desde IS NULL
       OR G.gramos_desde<0 OR (G.gramos_hasta IS NOT NULL AND G.gramos_hasta<G.gramos_desde)
       OR G.precio IS NULL OR G.precio<=0)
    THROW 52052,N'Cada calibre requiere variedad, rango en gramos y precio válido.',1;
  INSERT INTO @calibres(variedad,calibre,gramos_desde,gramos_hasta,precio)
   SELECT variedad,calibre,gramos_desde,gramos_hasta,precio
    FROM OPENJSON(@cJson,'$.datos.calibres') WITH(variedad SMALLINT '$.variedadPaltaId',
      calibre VARCHAR(12) '$.calibre',gramos_desde INT '$.gramosDesde',
      gramos_hasta INT '$.gramosHasta',precio DECIMAL(14,4) '$.precioKg');
  IF EXISTS(SELECT 1 FROM @precios P WHERE NOT EXISTS(SELECT 1 FROM @calibres G WHERE G.variedad=P.variedad))
    OR EXISTS(SELECT 1 FROM @calibres G WHERE NOT EXISTS(SELECT 1 FROM @precios P WHERE P.variedad=G.variedad))
    THROW 52053,N'Cada variedad requiere al menos un calibre, y cada calibre debe tener variedad vigente.',1;
  IF EXISTS(SELECT 1 FROM @calibres A JOIN @calibres B ON A.variedad=B.variedad AND A.indice<B.indice
     WHERE A.calibre=B.calibre OR (A.gramos_desde<=COALESCE(B.gramos_hasta,2147483647)
       AND B.gramos_desde<=COALESCE(A.gramos_hasta,2147483647)))
    THROW 52054,N'Los calibres de una misma variedad no pueden tener rangos solapados ni repetirse.',1;
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
  INSERT comercial.CampaniaVenta(asociacion_id,empresa_compradora_id,comprador_apappss_id,modalidad_venta_id,codigo,nombre,fecha_inicio,fecha_fin,estado_proceso,observacion,estado,uot_id,descuento_jaba_kg)
   VALUES(@asociacion,@empresa,@comprador,@modalidad,@codigo,@nombre,@inicio,@fin,'PLANIFICACION',@observacion,1,@uot,@descuento);
  SET @camp=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.PrecioComercial(campania_venta_id,operativo_venta_id,variedad_palta_id,condicion_comercial_id,
    precio,moneda,unidad_medida,fecha_vigencia_desde,fecha_vigencia_hasta,version,estado)
   SELECT @camp,NULL,P.variedad,@condicion,P.precio,'PEN','KG',CONVERT(DATETIME2(0),@inicio),NULL,1,1 FROM @precios P;
  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id)
    SELECT @camp,G.variedad,G.calibre,G.gramos_desde,G.gramos_hasta,G.precio,@usuario FROM @calibres G;
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
    SELECT G.campania_calibre_id,1,G.precio_kg,@usuario FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp;
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
  SET @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END;
  SET @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51400 AND 51499 OR ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
    ELSE N'No se pudo registrar la campaña y sus precios.' END;
 END CATCH;
END;
GO

-- Edición de una sola entidad CampaniaVenta con control de peso ya registrado.
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
  @descuento DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@appLock INT,
  @antes NVARCHAR(MAX),@despues NVARCHAR(MAX),@aud BIGINT,@trans BIGINT,
  @inicioAnterior DATE,@finAnterior DATE,@compradorAnterior BIGINT,@descuentoAnterior DECIMAL(9,3),
  @recursoLock NVARCHAR(255),@identificador NVARCHAR(200);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @comprador IS NULL
    OR @nombre IS NULL OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL
    OR @fin<@hoy OR @fin<@inicio OR (@descuento IS NOT NULL AND @descuento NOT BETWEEN 0 AND 9.999)
    OR LEN(COALESCE(@observacion,N''))>400
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
     @compradorAnterior=C.comprador_apappss_id,@descuentoAnterior=C.descuento_jaba_kg
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
  IF (COALESCE(@descuento,-1)<>COALESCE(@descuentoAnterior,-1)) AND EXISTS(
      SELECT 1 FROM comercial.CampaniaJabaRecepcion R
      JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp)
    THROW 52061,N'No puede cambiar el descuento cuando existen pesajes registrados.',1;
  SET @antes=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  UPDATE comercial.CampaniaVenta SET comprador_apappss_id=@comprador,empresa_compradora_id=@empresa,
   nombre=@nombre,fecha_inicio=@inicio,fecha_fin=@fin,observacion=@observacion,descuento_jaba_kg=@descuento
   WHERE campania_venta_id=@camp;
  SET @despues=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg
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
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 OR ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51901 AND 51999 OR ERROR_NUMBER() BETWEEN 52001 AND 52099 THEN LEFT(ERROR_MESSAGE(),300)
       ELSE N'No se pudo actualizar la campaña.' END;
 END CATCH;
END;
GO
