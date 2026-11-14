-- APAPPSS: registro inicial y corrección auditada son operaciones distintas.
-- Migración posterior a V625: no modifica V622 ya aplicada.
-- El registro inicial no sobrescribe un pesaje previo.
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
  ELSE THROW 52020,N'La jaba ya fue registrada. Utilice Corregir e indique el motivo.',1;
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


-- Corregir un pesaje existente exige motivo, versión original y registra antes/después.
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
  @motivo NVARCHAR(500)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.motivo'))),N''),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @uot BIGINT,@asignacion BIGINT,@asignadas INT,@estado VARCHAR(20),@descuento DECIMAL(9,3),@registradas INT,@id BIGINT,
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),@acceso BIT,@mensajeAcceso NVARCHAR(300),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),@appLock INT,
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),
  @pesoAnterior DECIMAL(12,3),@descuentoAnterior DECIMAL(9,3),@calibreAnterior BIGINT;
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @part IS NULL OR @numero IS NULL OR @numero<1
     OR @peso IS NULL OR @peso<0 OR @peso>999999 OR (@peso=0 AND @calibre IS NOT NULL)
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
    IF @calibre IS NULL AND (SELECT COUNT(1) FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp)=1
       SELECT @calibre=campania_calibre_id FROM comercial.CampaniaCalibre WHERE campania_venta_id=@camp;
    IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaCalibre WHERE campania_calibre_id=@calibre AND campania_venta_id=@camp)
       THROW 52018,N'Seleccione un calibre y variedad registrados en esta campaña.',1;
  END;
  IF @peso=0 SET @descuento=0;
  SELECT @id=campania_jaba_recepcion_id,@pesoAnterior=peso_bruto_kg,
    @descuentoAnterior=descuento_jaba_kg,@calibreAnterior=campania_calibre_id
   FROM comercial.CampaniaJabaRecepcion WITH(UPDLOCK,HOLDLOCK)
   WHERE campania_jaba_plan_id=@asignacion AND numero_jaba=@numero;
  IF @id IS NULL THROW 52020,N'Esta jaba aún no tiene un pesaje registrado.',1;
  IF @pesoAnterior=@peso AND @descuentoAnterior=@descuento
     AND ((@calibreAnterior=@calibre) OR (@calibreAnterior IS NULL AND @calibre IS NULL))
    THROW 52020,N'No hay cambios que guardar.',1;
  UPDATE comercial.CampaniaJabaRecepcion SET peso_bruto_kg=@peso,descuento_jaba_kg=@descuento,
    campania_calibre_id=@calibre,usuario_modifica_id=@usuario,fecha_modifica=SYSUTCDATETIME(),version=version+1
   WHERE campania_jaba_recepcion_id=@id AND version=@version;
  IF @@ROWCOUNT<>1 THROW 52019,N'El pesaje fue modificado por otro usuario; actualice la página.',1;
  SELECT @registradas=COUNT(1) FROM comercial.CampaniaJabaRecepcion WHERE campania_jaba_plan_id=@asignacion;
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
    VALUES(@camp,'CampaniaJabaRecepcion',@id,'CORREGIR_PESAJE',
      (SELECT @part participacionId,@numero numero,@pesoAnterior pesoAnteriorKg,
        @descuentoAnterior descuentoAnteriorKg,@calibreAnterior calibreAnteriorId,
        @peso pesoNuevoKg,@descuento descuentoNuevoKg,@calibre calibreNuevoId,
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
