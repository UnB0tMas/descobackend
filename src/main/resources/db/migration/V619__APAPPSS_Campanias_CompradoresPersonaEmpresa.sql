-- APAPPSS: compradores persona/empresa en campaña. Preservar campañas históricas.
IF COL_LENGTH(N'comercial.CampaniaVenta',N'comprador_apappss_id') IS NULL
    ALTER TABLE comercial.CampaniaVenta ADD comprador_apappss_id BIGINT NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'comercial.CampaniaVenta')
           AND name=N'empresa_compradora_id' AND is_nullable=0)
    ALTER TABLE comercial.CampaniaVenta ALTER COLUMN empresa_compradora_id BIGINT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID(N'comercial.CampaniaVenta')
               AND name=N'FK_CampaniaVenta_CompradorAPAPPSS')
    ALTER TABLE comercial.CampaniaVenta WITH CHECK ADD CONSTRAINT FK_CampaniaVenta_CompradorAPAPPSS
    FOREIGN KEY(comprador_apappss_id) REFERENCES comercial.CompradorAPAPPSS(comprador_apappss_id);
GO
-- Vincular el histórico sólo cuando hay una coincidencia exacta en la misma UOT.
UPDATE C SET comprador_apappss_id=B.comprador_apappss_id
FROM comercial.CampaniaVenta C
JOIN comercial.CompradorAPAPPSS B ON B.uot_id=C.uot_id AND B.tipo='EMPRESA'
  AND B.empresa_id=C.empresa_compradora_id AND B.estado=1
WHERE C.comprador_apappss_id IS NULL;
GO

-- APAPPSS: creación atómica de campaña con UNA modalidad y precio por variedad.
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
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@prev VARBINARY(32),@respuesta NVARCHAR(MAX),@codigo VARCHAR(40),@fecha DATETIME2(0)=SYSUTCDATETIME(),
  @hoy DATE=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()));
 DECLARE @precios TABLE(variedad SMALLINT NOT NULL PRIMARY KEY,precio DECIMAL(14,4) NOT NULL);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @uot IS NULL OR @asociacion IS NULL OR @comprador IS NULL OR @modalidad IS NULL OR @nombre IS NULL
    OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL OR @inicio<@hoy OR @fin<@hoy OR @fin<@inicio
    OR (@cupo IS NOT NULL AND @cupo NOT BETWEEN 1 AND 100000) OR LEN(COALESCE(@observacion,N''))>400
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
  INSERT comercial.CampaniaVenta(asociacion_id,empresa_compradora_id,comprador_apappss_id,modalidad_venta_id,codigo,nombre,fecha_inicio,fecha_fin,estado_proceso,observacion,estado,uot_id)
   VALUES(@asociacion,@empresa,@comprador,@modalidad,@codigo,@nombre,@inicio,@fin,'PLANIFICACION',@observacion,1,@uot);
  SET @camp=CONVERT(BIGINT,SCOPE_IDENTITY());
  INSERT comercial.PrecioComercial(campania_venta_id,operativo_venta_id,variedad_palta_id,condicion_comercial_id,
    precio,moneda,unidad_medida,fecha_vigencia_desde,fecha_vigencia_hasta,version,estado)
   SELECT @camp,NULL,P.variedad,@condicion,P.precio,'PEN','KG',CONVERT(DATETIME2(0),@inicio),NULL,1,1 FROM @precios P;
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

-- Restricción por asociación APAPPSS en listado sin alterar columnas o paginación.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_Listado]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nPagina INT,@nTamano INT,@nOffset BIGINT; EXEC seg.PA_Consulta_Sel_ResolverPaginacion @cJson,@nPagina OUTPUT,@nTamano OUTPUT,@nOffset OUTPUT;
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nUotSolicitada BIGINT,@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@cEstado VARCHAR(20),@nAsoc BIGINT,@nComprador BIGINT,@nCompradorAPAPPSS BIGINT,@dDesde DATE,@dHasta DATE;
        SELECT @nUotSolicitada=uotId,@cEstado=estadoProceso,@nAsoc=asociacionId,@nComprador=empresaCompradoraId,@nCompradorAPAPPSS=compradorId,@dDesde=fechaDesde,@dHasta=fechaHasta FROM OPENJSON(@cJson,'$.filtros') WITH(uotId BIGINT '$.uotId',estadoProceso VARCHAR(20) '$.estadoProceso',asociacionId BIGINT '$.asociacionId',empresaCompradoraId BIGINT '$.empresaCompradoraId',compradorId BIGINT '$.compradorId',fechaDesde DATE '$.fechaDesde',fechaHasta DATE '$.fechaHasta');
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_LISTAR',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_LISTAR',0,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        -- Sólo APAPPSS con convenio UOT real, activo y módulo especial explícito.
        IF @nUot IS NULL OR NOT EXISTS (
          SELECT 1 FROM org.ConvenioUOTOrganizacion CU
          JOIN org.Empresa E ON E.empresa_id=CU.empresa_id AND E.ruc='20602771394' AND E.estado=1
          JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
          JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
          JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CU.uot_id=@nUot AND CU.estado=1 AND CU.tipo_vinculo='ASOCIACION'
            AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
            AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
        BEGIN SET @cMensaje=N'No existe convenio APAPPSS vigente para la UOT seleccionada.'; GOTO Salida; END;
        SELECT C.campania_venta_id campaniaVentaId,C.uot_id uotId,U.codigo uotCodigo,U.nombre uotNombre,C.asociacion_id asociacionId,EA.razon_social asociacion,C.empresa_compradora_id empresaCompradoraId,C.comprador_apappss_id compradorId,COALESCE(CASE WHEN B.tipo='PERSONA' THEN NULLIF(TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))),N'') ELSE EB.razon_social END,EC.razon_social) empresaCompradora,C.codigo,C.nombre,C.fecha_inicio fechaInicio,C.fecha_fin fechaFin,C.estado_proceso estadoProceso,C.observacion,C.estado,COUNT_BIG(*) OVER() totalRegistros
        FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id LEFT JOIN org.Persona P ON P.persona_id=B.persona_id LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id
        WHERE C.estado=1 AND C.uot_id=@nUot AND EA.ruc='20602771394' AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,C.uot_id,'CAMPANIAS_LISTAR')=1 AND (@cEstado IS NULL OR C.estado_proceso=@cEstado) AND (@nAsoc IS NULL OR C.asociacion_id=@nAsoc) AND (@nComprador IS NULL OR C.empresa_compradora_id=@nComprador) AND (@nCompradorAPAPPSS IS NULL OR C.comprador_apappss_id=@nCompradorAPAPPSS) AND (@dDesde IS NULL OR C.fecha_inicio>=@dDesde) AND (@dHasta IS NULL OR C.fecha_inicio<=@dHasta)
        ORDER BY C.fecha_inicio DESC,C.campania_venta_id DESC OFFSET @nOffset ROWS FETCH NEXT @nTamano ROWS ONLY;
        SET @bResultado=1; SET @cMensaje=N'Campañas consultadas.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudieron consultar las campañas.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_Listado',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO

-- Restricción de detalle APAPPSS por UOT y convenio real, manteniendo respuesta original.
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Sel_DetalleCompleto]
    @cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,@nHttpRespuesta SMALLINT=NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;
    BEGIN TRY
        DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@bCtx BIT,@cMsg NVARCHAR(300),@nId BIGINT=COALESCE(TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campania.campaniaVentaId')),TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.campaniaVentaId'))),@nUotSolicitada BIGINT=TRY_CONVERT(BIGINT,COALESCE(JSON_VALUE(@cJson,'$.campania.uotId'),JSON_VALUE(@cJson,'$.uotId'))),@nUot BIGINT,@bGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300);
        IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
        EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,'CAMPANIAS_VER',@nUsuario OUTPUT,@nSesion OUTPUT,@nDisp OUTPUT,@nEmp OUTPUT,@nModulo OUTPUT,@gCorr OUTPUT,@gSol OUTPUT,@cIp OUTPUT,@cEnd OUTPUT,@bCtx OUTPUT,@cMsg OUTPUT;
        IF @bCtx=0 BEGIN SET @cMensaje=@cMsg; GOTO Salida; END;
        EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,'CAMPANIAS_VER',1,@nUot OUTPUT,@bGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
        IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Salida; END;
        IF NOT EXISTS (SELECT 1 FROM comercial.CampaniaVenta CV
          JOIN org.Empresa E ON E.empresa_id=CV.asociacion_id AND E.ruc='20602771394' AND E.estado=1
          JOIN org.Asociacion A ON A.asociacion_id=E.empresa_id AND A.estado=1
          JOIN org.ConvenioUOTOrganizacion CU ON CU.empresa_id=E.empresa_id AND CU.uot_id=CV.uot_id AND CU.estado=1
          JOIN org.UOT U ON U.uot_id=CU.uot_id AND U.estado=1 AND U.es_raiz=0
          JOIN org.ConvenioModuloEspecial CM ON CM.convenio_uot_organizacion_id=CU.convenio_uot_organizacion_id AND CM.estado=1
          JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=CM.modulo_especial_id AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
          WHERE CV.campania_venta_id=@nId AND CV.uot_id=@nUot AND CV.estado=1 AND CU.tipo_vinculo='ASOCIACION'
             AND (CU.fecha_inicio IS NULL OR CU.fecha_inicio<=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME())))
             AND (CU.fecha_fin IS NULL OR CU.fecha_fin>=CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))))
        BEGIN SET @cMensaje=N'La campaña no pertenece a un convenio APAPPSS vigente en esta UOT.'; GOTO Salida; END;
        IF NOT EXISTS(SELECT 1 FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1) BEGIN SET @cMensaje=N'La campaña no está disponible en esta UOT.'; GOTO Salida; END;
        SELECT C.*,U.codigo uotCodigo,U.nombre uotNombre,EA.razon_social asociacion,COALESCE(CASE WHEN B.tipo='PERSONA' THEN NULLIF(TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))),N'') ELSE EB.razon_social END,EC.razon_social) empresaCompradora FROM comercial.CampaniaVenta C JOIN org.UOT U ON U.uot_id=C.uot_id JOIN org.Empresa EA ON EA.empresa_id=C.asociacion_id LEFT JOIN org.Empresa EC ON EC.empresa_id=C.empresa_compradora_id LEFT JOIN comercial.CompradorAPAPPSS B ON B.comprador_apappss_id=C.comprador_apappss_id AND B.uot_id=C.uot_id LEFT JOIN org.Persona P ON P.persona_id=B.persona_id LEFT JOIN org.Empresa EB ON EB.empresa_id=B.empresa_id WHERE C.campania_venta_id=@nId AND C.uot_id=@nUot;
        SELECT O.* FROM comercial.OperativoVenta O WHERE O.campania_venta_id=@nId ORDER BY O.operativo_venta_id;
        SET @bResultado=1; SET @cMensaje=N'Campaña consultada.';
    END TRY BEGIN CATCH SET @bResultado=0; SET @cMensaje=N'No se pudo consultar la campaña.'; END CATCH
Salida:
    SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Sel_DetalleCompleto',@bResultado,@cMensaje) R;
    RETURN CASE WHEN @bResultado=1 THEN 0 ELSE 1 END;
END;
GO

-- APAPPSS: exponer modalidad seleccionada y referencia interna para precios.
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
  SET @cDatos=(SELECT C.campania_venta_id campaniaId,C.modalidad_venta_id modalidadVentaId,
    C.comprador_apappss_id compradorId,B.tipo tipoComprador,
    COALESCE(CASE WHEN B.tipo='PERSONA' THEN NULLIF(TRIM(CONCAT(P.nombres,N' ',P.apellido_paterno,N' ',COALESCE(P.apellido_materno,N''))),N'') ELSE EB.razon_social END,EC.razon_social) compradorNombre,
    (SELECT TOP(1) CC.condicion_comercial_id FROM comercial.CondicionComercial CC
     WHERE CC.modalidad_venta_id=C.modalidad_venta_id
      AND CC.codigo=CONCAT('APAPPSS_MODALIDAD_',CONVERT(VARCHAR(12),C.modalidad_venta_id)) AND CC.estado=1) condicionComercialId,
    K.cupo_jabas cupoJabas,K.tara_kg taraKg,
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

-- Editar datos de campaña exclusivamente mientras esté en planificación.
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
  @recursoLock NVARCHAR(255),@identificador NVARCHAR(200);
 BEGIN TRY
  IF ISJSON(@cJson)<>1 OR @clave IS NULL OR @camp IS NULL OR @comprador IS NULL
    OR @nombre IS NULL OR LEN(@nombre)>180 OR @inicio IS NULL OR @fin IS NULL
    OR @inicio<@hoy OR @fin<@inicio OR LEN(COALESCE(@observacion,N''))>400
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
  SELECT @estado=C.estado_proceso FROM comercial.CampaniaVenta C WITH(UPDLOCK,HOLDLOCK)
   WHERE C.campania_venta_id=@camp AND C.uot_id=@uot AND C.estado=1;
  IF @estado IS NULL OR @estado<>'PLANIFICACION'
    THROW 51907,N'Solo puede modificar una campaña en planificación.',1;
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
