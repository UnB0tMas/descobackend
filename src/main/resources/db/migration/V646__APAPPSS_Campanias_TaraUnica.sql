-- V646: Una sola tara para campañas y recepción de jabas APAPPSS.
-- El campo físico descuento_jaba_kg se mantiene como espejo técnico para compatibilidad;
-- no representa un descuento adicional ni se suma a tara_kg.
-- No tocar migraciones anteriores ni reescribir pesajes históricos durante la reconciliación.

-- La recepción anterior utilizó el valor en CampaniaVenta: respetarlo cuando exista,
-- particularmente si hay pesajes; en ausencia de dicho valor conservar tara_kg vigente.
UPDATE K SET tara_kg=CASE WHEN C.descuento_jaba_kg IS NOT NULL THEN C.descuento_jaba_kg
  WHEN EXISTS (SELECT 1 FROM comercial.CampaniaJabaRecepcion R
       JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
       WHERE P.campania_venta_id=C.campania_venta_id) THEN 0
  ELSE K.tara_kg END
FROM comercial.CampaniaControlE4 K
JOIN comercial.CampaniaVenta C ON C.campania_venta_id=K.campania_venta_id
WHERE K.tara_kg<>CASE WHEN C.descuento_jaba_kg IS NOT NULL THEN C.descuento_jaba_kg
  WHEN EXISTS (SELECT 1 FROM comercial.CampaniaJabaRecepcion R
       JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
       JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
       WHERE P.campania_venta_id=C.campania_venta_id) THEN 0
  ELSE K.tara_kg END;

UPDATE C SET descuento_jaba_kg=K.tara_kg
FROM comercial.CampaniaVenta C
JOIN comercial.CampaniaControlE4 K ON K.campania_venta_id=C.campania_venta_id
WHERE C.descuento_jaba_kg IS NULL;
GO

-- Las mutaciones existentes de E4 quedan intactas; su tara sincroniza el pesaje
-- convencional solo cuando cambia realmente y dentro de la misma transacción.
CREATE OR ALTER TRIGGER comercial.TR_CampaniaControlE4_TaraVenta
ON comercial.CampaniaControlE4
AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT UPDATE(tara_kg) RETURN;
 DECLARE @cambios TABLE(campaniaId BIGINT NOT NULL PRIMARY KEY,valor DECIMAL(9,3) NOT NULL,usuario BIGINT NOT NULL);
 INSERT @cambios(campaniaId,valor,usuario)
 SELECT I.campania_venta_id,I.tara_kg,I.usuario_id
 FROM inserted I
 LEFT JOIN deleted D ON D.campania_venta_id=I.campania_venta_id
 WHERE D.campania_venta_id IS NULL OR I.tara_kg<>D.tara_kg;
 IF NOT EXISTS(SELECT 1 FROM @cambios) RETURN;
 -- Las configuraciones del aplicativo afectan una campaña por operación.
 IF (SELECT COUNT(*) FROM @cambios)>1 THROW 52077,N'Configure la tara de cada campaña por separado.',1;
 DECLARE @camp BIGINT,@tara DECIMAL(9,3),@usuario BIGINT;
 SELECT @camp=campaniaId,@tara=valor,@usuario=usuario FROM @cambios;
 IF EXISTS(SELECT 1 FROM comercial.CampaniaVenta C
     WHERE C.campania_venta_id=@camp AND ISNULL(C.descuento_jaba_kg,-1)<>@tara)
 BEGIN
   EXEC comercial.PA_CampaniaDescuentoJaba_Upd_Recalcular @camp,@tara,@usuario;
   UPDATE comercial.CampaniaVenta SET descuento_jaba_kg=@tara WHERE campania_venta_id=@camp;
 END;
END;
GO

-- En alta, la tara queda persistida tanto en K como en el espejo compatible C.
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
  @origen VARCHAR(12)=COALESCE(NULLIF(UPPER(TRIM(JSON_VALUE(@cJson,'$.datos.origenJabas'))),''),'UOT'),
  @descuento DECIMAL(9,3)=TRY_CONVERT(DECIMAL(9,3),JSON_VALUE(@cJson,'$.datos.descuentoJabaKg')),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@codigo VARCHAR(40),@fecha DATETIME2(0)=SYSUTCDATETIME(),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 DECLARE @precios TABLE(variedad SMALLINT NOT NULL PRIMARY KEY,precio DECIMAL(14,4) NOT NULL);
 DECLARE @calibres TABLE(indice INT IDENTITY(1,1) PRIMARY KEY,variedad SMALLINT NOT NULL,calibre VARCHAR(12) NOT NULL,
   gramos_desde INT NOT NULL,gramos_hasta INT NULL,precio DECIMAL(14,4) NOT NULL);
 BEGIN TRY
  IF @origen NOT IN('UOT','ASOCIACION') THROW 52071,N'El origen de las jabas no es válido.',1;
  IF @cupo IS NULL AND COALESCE(@descuento,0)>0
    THROW 52074,N'Defina el cupo antes de configurar la tara.',1;
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
  INSERT comercial.CampaniaVenta(asociacion_id,empresa_compradora_id,comprador_apappss_id,modalidad_venta_id,codigo,nombre,fecha_inicio,fecha_fin,estado_proceso,observacion,estado,uot_id,descuento_jaba_kg,origen_jabas)
   VALUES(@asociacion,@empresa,@comprador,@modalidad,@codigo,@nombre,@inicio,@fin,'PLANIFICACION',@observacion,1,@uot,@descuento,@origen);
  SET @camp=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.PrecioComercial(campania_venta_id,operativo_venta_id,variedad_palta_id,condicion_comercial_id,
    precio,moneda,unidad_medida,fecha_vigencia_desde,fecha_vigencia_hasta,version,estado)
   SELECT @camp,NULL,P.variedad,@condicion,P.precio,'PEN','KG',CONVERT(DATETIME2(0),@inicio),NULL,1,1 FROM @precios P;
  INSERT comercial.CampaniaCalibre(campania_venta_id,variedad_palta_id,calibre,gramos_desde,gramos_hasta,precio_kg,usuario_registro_id)
    SELECT @camp,G.variedad,G.calibre,G.gramos_desde,G.gramos_hasta,G.precio,@usuario FROM @calibres G;
  INSERT comercial.CampaniaCalibrePrecioVersion(campania_calibre_id,version,precio_kg,usuario_id)
    SELECT G.campania_calibre_id,1,G.precio_kg,@usuario FROM comercial.CampaniaCalibre G WHERE G.campania_venta_id=@camp;
  IF @cupo IS NOT NULL INSERT comercial.CampaniaControlE4(campania_venta_id,cupo_jabas,tara_kg,usuario_id)
   VALUES(@camp,@cupo,COALESCE(@descuento,0),@usuario);
  INSERT comercial.EventoE4(campania_venta_id,entidad,entidad_id,accion,detalle,usuario_id)
   VALUES(@camp,'CampaniaVenta',@camp,'CREAR_PLAN',(SELECT COUNT(*) precios,@cupo cupoJabas FROM @precios FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),@usuario);
  SET @cDatos=(SELECT @camp campaniaVentaId,(SELECT COUNT(1) FROM @precios) preciosCreados,@cupo cupoJabas,@origen origenJabas FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
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


-- El resto de campos de planificación no puede volver a modificar la tara.
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
  @origen VARCHAR(12)=NULLIF(UPPER(TRIM(JSON_VALUE(@cJson,'$.datos.origenJabas'))),''),@origenAnterior VARCHAR(12),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@appLock INT,
  @antes NVARCHAR(MAX),@despues NVARCHAR(MAX),@aud BIGINT,@trans BIGINT,
  @inicioAnterior DATE,@finAnterior DATE,@compradorAnterior BIGINT,@descuentoAnterior DECIMAL(9,3),
  @recursoLock NVARCHAR(255),@identificador NVARCHAR(200);
 BEGIN TRY
  IF @origen IS NOT NULL AND @origen NOT IN('UOT','ASOCIACION') THROW 52071,N'El origen de las jabas no es válido.',1;
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
     @compradorAnterior=C.comprador_apappss_id,@descuentoAnterior=C.descuento_jaba_kg,
     @origenAnterior=C.origen_jabas
    FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
    WHERE C.campania_venta_id=@camp AND C.uot_id=@uot AND C.estado=1;
  IF @descuento IS NOT NULL AND COALESCE(@descuento,-1)<>COALESCE(@descuentoAnterior,-1)
    THROW 52075,N'La tara se configura desde el cupo de jabas.',1;
  SET @descuento=@descuentoAnterior;
  SET @origen=COALESCE(@origen,@origenAnterior);
  IF @origen NOT IN('UOT','ASOCIACION') THROW 52071,N'El origen de las jabas no es válido.',1;
  IF @estado IS NULL OR @estado NOT IN('PLANIFICACION','ACTIVA')
    THROW 51907,N'La campaña ya no admite cambios.',1;
  IF @inicio<@hoy AND @inicio<>@inicioAnterior
    THROW 51908,N'No puede cambiar el inicio a una fecha anterior a hoy.',1;
  -- En campaña activa solo se actualizan nombre y observación; se respeta la relación comercial.
  IF @estado='ACTIVA' AND (@inicio<>@inicioAnterior OR @fin<>@finAnterior
       OR ISNULL(@comprador,-1)<>ISNULL(@compradorAnterior,-1))
    THROW 51909,N'En una campaña activa solo puede modificar nombre y observación.',1;
  IF @origen<>@origenAnterior AND (
      @estado<>'PLANIFICACION'
      OR EXISTS(SELECT 1 FROM comercial.CampaniaJabaPlan J
        JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
        WHERE P.campania_venta_id=@camp AND J.activo=1 AND J.estado IN('ENTREGADA','DEVUELTA'))
      OR EXISTS(SELECT 1 FROM comercial.JabaAsignacion A
        JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=A.operativo_socio_id
        JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
        WHERE O.campania_venta_id=@camp AND A.estado=1))
    THROW 52072,N'No puede cambiar el origen cuando ya existen jabas entregadas u operativos.',1;
  IF (COALESCE(@descuento,-1)<>COALESCE(@descuentoAnterior,-1)) AND EXISTS(
      SELECT 1 FROM comercial.CampaniaJabaRecepcion R
      JOIN comercial.CampaniaJabaPlan J ON J.campania_jaba_plan_id=R.campania_jaba_plan_id
      JOIN comercial.ParticipacionCampaniaSocio P ON P.participacion_campania_socio_id=J.participacion_campania_socio_id
      WHERE P.campania_venta_id=@camp)
    THROW 52061,N'No puede cambiar el descuento cuando existen pesajes registrados.',1;
  SET @antes=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg,origen_jabas
    FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  UPDATE comercial.CampaniaVenta SET comprador_apappss_id=@comprador,empresa_compradora_id=@empresa,
   nombre=@nombre,fecha_inicio=@inicio,fecha_fin=@fin,observacion=@observacion,descuento_jaba_kg=@descuento,origen_jabas=@origen
   WHERE campania_venta_id=@camp;
  SET @despues=(SELECT campania_venta_id,comprador_apappss_id,empresa_compradora_id,nombre,fecha_inicio,fecha_fin,observacion,descuento_jaba_kg,origen_jabas
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


-- End-point legacy, si un consumidor antiguo aún lo usa, actualiza la tara real.
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
  -- El nuevo descuento también actualiza los pesajes existentes con auditoría.
  IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@camp AND estado_proceso IN('PLANIFICACION','ACTIVA'))
    THROW 52026,N'La campaña no admite modificaciones.',1;
  UPDATE comercial.CampaniaControlE4 SET tara_kg=COALESCE(@valor,0),version=version+1,
    usuario_id=@usuario,actualizado_en=SYSUTCDATETIME() WHERE campania_venta_id=@camp;
  IF @@ROWCOUNT<>1 THROW 52076,N'Configure el cupo de jabas antes de cambiar la tara.',1;
  -- TR_CampaniaControlE4_TaraVenta sincroniza el campo técnico y recalcula los pesajes auditables.
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
