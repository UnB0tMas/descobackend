-- APAPPSS: pesaje sucesivo y confirmación final de entrega por socio.
-- Los pesajes se mantienen y la confirmación final es independiente y auditada.
IF COL_LENGTH(N'comercial.CampaniaJabaPlan',N'recepcion_confirmada') IS NULL
  ALTER TABLE comercial.CampaniaJabaPlan ADD recepcion_confirmada BIT NOT NULL
    CONSTRAINT DF_CampaniaJabaPlan_RecepcionConfirmada DEFAULT(0);
GO
IF COL_LENGTH(N'comercial.CampaniaJabaPlan',N'fecha_confirmacion_recepcion') IS NULL
  ALTER TABLE comercial.CampaniaJabaPlan ADD fecha_confirmacion_recepcion DATETIME2(0) NULL;
GO
IF COL_LENGTH(N'comercial.CampaniaJabaPlan',N'usuario_confirmacion_recepcion_id') IS NULL
  ALTER TABLE comercial.CampaniaJabaPlan ADD usuario_confirmacion_recepcion_id BIGINT NULL;
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
       CONCAT(PE.nombres,N' ',PE.apellido_paterno,N' ',COALESCE(PE.apellido_materno,N'')) socioNombre,J.cantidad asignadas,J.estado estadoJabas,CAST(J.recepcion_confirmada AS BIT) recepcionConfirmada,
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
  @uot BIGINT,@asignacion BIGINT,@asignadas INT,@estado VARCHAR(20),@confirmada BIT,@descuento DECIMAL(9,3),@registradas INT,@id BIGINT,
  @stock INT,@entregadas BIGINT,@existentes BIGINT,
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
  SELECT @asignacion=J.campania_jaba_plan_id,@asignadas=J.cantidad,@estado=J.estado,@confirmada=J.recepcion_confirmada
   FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
   JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
   WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@part
      AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1;
  IF @asignacion IS NULL OR @estado NOT IN('PENDIENTE_RECOJO','ENTREGADA','DEVUELTA')
     OR @numero>@asignadas OR ISNULL(@confirmada,0)=1
    THROW 52016,N'Esta asignación ya fue confirmada o no permite registrar más jabas.',1;
  -- Al iniciar el pesaje, registrar la entrega inicial dentro de la misma transacción,
  -- aplicando el control de stock existente para no comprometer otras asignaciones.
  IF @estado='PENDIENTE_RECOJO'
  BEGIN
    SELECT @stock=existencia_certificada FROM comercial.JabaStockUotE4 WITH(UPDLOCK,HOLDLOCK)
      WHERE uot_id=@uot;
    IF @stock IS NULL THROW 51456,N'Primero certifique el stock físico de jabas de esta unidad.',1;
    SELECT @entregadas=COALESCE(SUM(CONVERT(BIGINT,J.cantidad)),0)
      FROM comercial.CampaniaJabaPlan J
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
      JOIN comercial.CampaniaVenta C ON C.campania_venta_id=P.campania_venta_id
      WHERE C.uot_id=@uot AND J.activo=1 AND J.estado='ENTREGADA';
    SELECT @existentes=COALESCE(SUM(CONVERT(BIGINT,A.cantidad_asignada)-COALESCE(V.cantidad_validada,0)),0)
      FROM comercial.JabaAsignacion A
      JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
      JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
      JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
      LEFT JOIN comercial.JabaRetornoValidadoE4 V ON V.jaba_asignacion_id=A.jaba_asignacion_id
      WHERE C.uot_id=@uot AND A.estado=1;
    IF @entregadas+@existentes+@asignadas>@stock
      THROW 51457,N'No existen suficientes jabas disponibles para iniciar la recepción.',1;
    UPDATE comercial.CampaniaJabaPlan SET estado='ENTREGADA',fecha_entrega=SYSUTCDATETIME(),
      usuario_modifica_id=@usuario,version=version+1
      WHERE campania_jaba_plan_id=@asignacion AND estado='PENDIENTE_RECOJO';
    IF @@ROWCOUNT<>1 THROW 52016,N'La asignación cambió. Actualice el detalle.',1;
    INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
      VALUES(@camp,'CampaniaJabaPlan',@asignacion,'ENTREGAR_JABAS',
        (SELECT @asignadas cantidad FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
    SET @estado='ENTREGADA';
  END;
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
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52001 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo registrar la jaba.' END;
 END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE comercial.PA_CampaniaJabaRecepcion_Upd_Confirmar
 @cJson NVARCHAR(MAX),@cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,@nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo confirmar la recepción.',
   @cCodigoRespuesta='RECEPCION_CONFIRMACION_ERROR',@nHttpRespuesta=400;
 DECLARE @camp BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.campaniaId')),
  @part BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.participacionId')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@plan BIGINT,@asignadas INT,@registradas INT,@estado VARCHAR(20),@confirmada BIT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @acceso BIT,@mensajeAcceso NVARCHAR(300),@lock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 BEGIN TRY
  IF @camp IS NULL OR @part IS NULL OR @clave IS NULL
    THROW 52030,N'Indique la campaña y el socio.',1;
  SELECT @uot=C.uot_id FROM comercial.CampaniaVenta C WHERE C.campania_venta_id=@camp AND C.estado=1;
  IF @uot IS NULL THROW 52031,N'La campaña no está disponible.',1;
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson=@cJson,@cCodigoPermiso='JABAS_CREAR',
   @nUsuarioId=@usuario OUTPUT,@nSesionUsuarioId=@sesion OUTPUT,@nDispositivoUsuarioId=@dispositivo OUTPUT,
   @nEmpleadoId=@empleado OUTPUT,@nModuloId=@modulo OUTPUT,@gCorrelacionId=@corr OUTPUT,
   @gSolicitudId=@sol OUTPUT,@cIp=@ip OUTPUT,@cEndpoint=@endpoint OUTPUT,
   @bResultado=@acceso OUTPUT,@cMensaje=@mensajeAcceso OUTPUT;
  IF ISNULL(@acceso,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,'JABAS_CREAR')<>1
    THROW 52032,N'No tiene permiso para confirmar la recepción.',1;
  SET @hash=HASHBYTES('SHA2_256',CONCAT(N'RECEPCION_CONFIRMAR|',@camp,'|',@part));
  BEGIN TRANSACTION;
  DECLARE @recurso NVARCHAR(255)=CONCAT(N'DESCO:E4:UOT:',@uot);
  EXEC @lock=sys.sp_getapplock @Resource=@recurso,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
  IF @lock<0 THROW 52033,N'Otra operación está procesando las jabas.',1;
  SELECT @prev=huella,@respuesta=respuesta FROM comercial.SolicitudE4 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
  IF @prev IS NOT NULL
  BEGIN
    IF @prev<>@hash THROW 52034,N'Esta solicitud ya se utilizó para otra operación.',1;
    SELECT @cDatos=@respuesta,@bResultado=1,@cMensaje=N'Confirmación registrada anteriormente.',
      @cCodigoRespuesta='RECEPCION_CONFIRMADA_OK',@nHttpRespuesta=200;
    COMMIT TRANSACTION;RETURN;
  END;
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
      WHERE C.campania_venta_id=@camp AND C.estado=1 AND C.estado_proceso IN('PLANIFICACION','ACTIVA')
      AND @hoy BETWEEN C.fecha_inicio AND C.fecha_fin)
    THROW 52035,N'La recepción solo puede confirmarse durante la campaña vigente.',1;
  SELECT @plan=J.campania_jaba_plan_id,@asignadas=J.cantidad,@estado=J.estado,
    @confirmada=J.recepcion_confirmada
    FROM comercial.CampaniaJabaPlan J WITH(UPDLOCK,HOLDLOCK)
    JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
    WHERE P.campania_venta_id=@camp AND P.participacion_campania_socio_id=@part
      AND P.estado=1 AND P.estado_participacion='ACTIVO' AND J.activo=1;
  IF @plan IS NULL OR @asignadas<1 OR @estado NOT IN('ENTREGADA','DEVUELTA') OR ISNULL(@confirmada,0)=1
    THROW 52036,N'La recepción ya fue confirmada o no está disponible.',1;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion R WITH(UPDLOCK,HOLDLOCK)
    WHERE R.campania_jaba_plan_id=@plan;
  IF @registradas<>@asignadas
    THROW 52037,N'Debe registrar todas las jabas antes de confirmar la entrega.',1;
  UPDATE comercial.CampaniaJabaPlan SET recepcion_confirmada=1,
    fecha_confirmacion_recepcion=SYSUTCDATETIME(),usuario_confirmacion_recepcion_id=@usuario,
    estado='DEVUELTA',fecha_devolucion=COALESCE(fecha_devolucion,SYSUTCDATETIME()),
    usuario_modifica_id=@usuario,version=version+1
    WHERE campania_jaba_plan_id=@plan AND recepcion_confirmada=0;
  IF @@ROWCOUNT<>1 THROW 52036,N'La recepción cambió. Actualice el detalle.',1;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaPlan',@plan,'CONFIRMAR_RECEPCION',
      (SELECT @part participacionId,@asignadas jabasRegistradas,
       (SELECT COALESCE(SUM(R.peso_bruto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=@plan) pesoBrutoKg,
       (SELECT COALESCE(SUM(R.peso_neto_kg),0) FROM comercial.CampaniaJabaRecepcion R WHERE R.campania_jaba_plan_id=@plan) pesoNetoKg
       FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @part participacionId,@asignadas asignadas,@registradas registradas,
      'DEVUELTA' estado,CAST(1 AS BIT) recepcionConfirmada FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  INSERT comercial.SolicitudE4(usuario_id,clave,accion,huella,respuesta)
    VALUES(@usuario,@clave,'RECEPCION_CONFIRMAR',@hash,@cDatos);
  COMMIT TRANSACTION;
  SELECT @bResultado=1,@cMensaje=N'Entrega confirmada.',@cCodigoRespuesta='RECEPCION_CONFIRMADA_OK',@nHttpRespuesta=200;
 END TRY BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  SELECT @cDatos=NULL,@bResultado=0,@cCodigoRespuesta='RECEPCION_CONFIRMACION_ERROR',
    @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 52000 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499 THEN 409 ELSE 500 END,
    @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 52000 AND 52099 OR ERROR_NUMBER() BETWEEN 51400 AND 51499
       THEN LEFT(ERROR_MESSAGE(),300) ELSE N'No se pudo confirmar la recepción.' END;
 END CATCH;
END;
GO
