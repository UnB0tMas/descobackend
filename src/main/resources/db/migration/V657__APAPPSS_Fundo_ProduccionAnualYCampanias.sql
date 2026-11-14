-- DESCO/APAPSA: produccion anual por fundo, complementaria al expediente individual E3.
-- No migra ni modifica las plantas existentes; una estimacion sugerida NO habilita campañas.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'prod.FundoProduccionE3',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoProduccionE3(
  fundo_produccion_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FundoProduccionE3 PRIMARY KEY,
  predio_id BIGINT NOT NULL REFERENCES prod.Predio(predio_id),
  uot_id BIGINT NOT NULL REFERENCES org.UOT(uot_id),
  convenio_id BIGINT NOT NULL REFERENCES org.ConvenioUOTOrganizacion(convenio_uot_organizacion_id),
  anio SMALLINT NOT NULL,
  fecha_desde DATE NOT NULL,
  fecha_hasta DATE NOT NULL,
  estado_produccion VARCHAR(20) NOT NULL,
  cantidad_disponible_kg DECIMAL(14,3) NOT NULL,
  observacion NVARCHAR(400) NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  actualizado_en DATETIME2(0) NOT NULL CONSTRAINT DF_FundoProduccionE3_Actualizado DEFAULT SYSUTCDATETIME(),
  version BIGINT NOT NULL CONSTRAINT DF_FundoProduccionE3_Version DEFAULT (1),
  CONSTRAINT UQ_FundoProduccionE3_AmbitoAnio UNIQUE(predio_id,convenio_id,anio),
  CONSTRAINT CK_FundoProduccionE3_Valido CHECK(
   anio BETWEEN 2000 AND 2200 AND fecha_desde<=fecha_hasta
   AND YEAR(fecha_desde)=anio AND YEAR(fecha_hasta)=anio
   AND ((estado_produccion='NO_DISPONIBLE' AND cantidad_disponible_kg=0)
    OR (estado_produccion IN('PARCIAL','DISPONIBLE') AND cantidad_disponible_kg>0))
  )
 );
 CREATE INDEX IX_FundoProduccionE3_Campania ON prod.FundoProduccionE3
  (uot_id,fecha_desde,fecha_hasta,predio_id)
  INCLUDE(convenio_id,estado_produccion,cantidad_disponible_kg);
END;
GO
IF OBJECT_ID(N'prod.FundoProduccionHistorialE3',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoProduccionHistorialE3(
  historial_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FundoProduccionHistorialE3 PRIMARY KEY,
  fundo_produccion_id BIGINT NOT NULL REFERENCES prod.FundoProduccionE3(fundo_produccion_id),
  anterior NVARCHAR(MAX) NULL,
  nuevo NVARCHAR(MAX) NOT NULL,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_FundoProduccionHistorialE3_Fecha DEFAULT SYSUTCDATETIME()
 );
END;
GO
IF OBJECT_ID(N'prod.FundoProduccionSolicitudE3',N'U') IS NULL
BEGIN
 CREATE TABLE prod.FundoProduccionSolicitudE3(
  solicitud_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FundoProduccionSolicitudE3 PRIMARY KEY,
  usuario_id BIGINT NOT NULL REFERENCES seg.Usuario(usuario_id),
  clave UNIQUEIDENTIFIER NOT NULL,
  hash_peticion VARBINARY(32) NOT NULL,
  respuesta NVARCHAR(MAX) NULL,
  fecha_hora DATETIME2(0) NOT NULL CONSTRAINT DF_FundoProduccionSolicitudE3_Fecha DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_FundoProduccionSolicitudE3_Clave UNIQUE(usuario_id,clave)
 );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'comercial.EntregaSocio')
 AND name=N'IX_EntregaSocio_FundoProduccion')
 CREATE INDEX IX_EntregaSocio_FundoProduccion
 ON comercial.EntregaSocio(predio_id,fecha_hora)
 INCLUDE(entrega_socio_id,operativo_socio_id,estado,estado_proceso);
GO
CREATE OR ALTER PROCEDURE prod.PA_FundoProduccionE3_Ejecutar
 @cAccion VARCHAR(20),@cJson NVARCHAR(MAX),
 @cDatos NVARCHAR(MAX) OUTPUT,@bResultado BIT OUTPUT,
 @cMensaje NVARCHAR(300) OUTPUT,@cCodigoRespuesta VARCHAR(60) OUTPUT,
 @nHttpRespuesta SMALLINT OUTPUT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 SELECT @cDatos=NULL,@bResultado=0,@cMensaje=N'No se pudo consultar la produccion del fundo.',
  @cCodigoRespuesta='FUNDO_PRODUCCION_ERROR',@nHttpRespuesta=400;
 DECLARE @uot BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.uotId')),
  @conv BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.convenioId')),
  @predio BIGINT=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.filtros.predioId')),
  @anio SMALLINT=TRY_CONVERT(SMALLINT,JSON_VALUE(@cJson,'$.filtros.anio')),
  @usuario BIGINT,@sesion BIGINT,@dispositivo BIGINT,@empleado BIGINT,@modulo INT,
  @corr UNIQUEIDENTIFIER,@sol UNIQUEIDENTIFIER,@ip VARCHAR(64),@endpoint NVARCHAR(250),
  @auth BIT,@authMsg NVARCHAR(300),@perm VARCHAR(60),
  @clave UNIQUEIDENTIFIER=TRY_CONVERT(UNIQUEIDENTIFIER,JSON_VALUE(@cJson,'$.contexto.claveIdempotencia')),
  @hash VARBINARY(32),@hashAnterior VARBINARY(32),@respuestaAnterior NVARCHAR(MAX),
  @fechaDesde DATE,@fechaHasta DATE,@estado VARCHAR(20),@cantidad DECIMAL(14,3),
  @observacion NVARCHAR(400),@id BIGINT,@versionEsperada BIGINT,@versionActual BIGINT=0,@antes NVARCHAR(MAX),
  @plantas BIGINT=0,@conEstimacion BIGINT=0,@conCosecha BIGINT=0,
  @estPlantas DECIMAL(19,3)=0,@realPlantas DECIMAL(19,3)=0,
  @mediaCosecha DECIMAL(19,3)=0,@mediaVentas DECIMAL(19,3)=0,
  @sugerido DECIMAL(19,3)=0,@origen VARCHAR(40)='SIN_DATOS',@calidad VARCHAR(10)='BAJA';
 IF ISJSON(@cJson)<>1 OR @uot IS NULL OR @uot<=0 OR @conv IS NULL OR @conv<=0
  OR @predio IS NULL OR @predio<=0 OR @anio IS NULL OR @anio NOT BETWEEN 2000 AND 2200
  OR @cAccion NOT IN('VER','GUARDAR')
 BEGIN SET @cMensaje=N'Indique convenio, fundo y año validos.'; RETURN; END;
 SET @perm=CASE WHEN @cAccion='VER' THEN 'APAPPSS_PREDIOS_VER' ELSE 'APAPPSS_PREDIOS_EDITAR' END;
 BEGIN TRY
  EXEC seg.PA_Operacion_Sel_ContextoAutorizado @cJson,@perm,
   @usuario OUTPUT,@sesion OUTPUT,@dispositivo OUTPUT,@empleado OUTPUT,@modulo OUTPUT,
   @corr OUTPUT,@sol OUTPUT,@ip OUTPUT,@endpoint OUTPUT,@auth OUTPUT,@authMsg OUTPUT;
  IF ISNULL(@auth,0)<>1 OR seg.FN_Usuario_TienePermisoUOT(@usuario,@uot,@perm)<>1
   THROW 51801,N'Sin permisos para consultar este fundo.',1;
  IF NOT EXISTS(
   SELECT 1 FROM prod.PredioAmbito A
   JOIN org.ConvenioUOTOrganizacion C ON C.convenio_uot_organizacion_id=A.convenio_uot_organizacion_id
    AND C.uot_id=@uot AND C.estado=1
    AND (C.fecha_inicio IS NULL OR C.fecha_inicio<=CONVERT(DATE,SYSUTCDATETIME()))
    AND (C.fecha_fin IS NULL OR C.fecha_fin>=CONVERT(DATE,SYSUTCDATETIME()))
   JOIN org.ConvenioModuloEspecial M ON M.convenio_uot_organizacion_id=C.convenio_uot_organizacion_id AND M.estado=1
   JOIN seg.ModuloEspecial ME ON ME.modulo_especial_id=M.modulo_especial_id
    AND ME.codigo='COMERCIALIZACION_ASOCIATIVA' AND ME.estado=1
   JOIN prod.Predio PD ON PD.predio_id=A.predio_id AND PD.estado=1
   WHERE A.predio_id=@predio AND A.uot_id=@uot AND A.convenio_uot_organizacion_id=@conv AND A.estado=1
     AND EXISTS(SELECT 1 FROM prod.PredioTitularidad T
       JOIN org.Socio S ON S.socio_id=T.socio_id AND S.estado=1
       JOIN org.SocioAsociacion SA ON SA.socio_id=T.socio_id AND SA.asociacion_id=C.empresa_id
        AND SA.estado=1 AND SA.fecha_desde<=CONVERT(DATE,SYSUTCDATETIME())
        AND (SA.fecha_hasta IS NULL OR SA.fecha_hasta>=CONVERT(DATE,SYSUTCDATETIME()))
       WHERE T.predio_id=@predio AND T.estado=1 AND T.fecha_hasta IS NULL)
  ) THROW 51802,N'El fundo no pertenece al convenio autorizado.',1;

  IF @cAccion='GUARDAR'
  BEGIN
   SELECT @fechaDesde=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaDesde')),
    @fechaHasta=TRY_CONVERT(DATE,JSON_VALUE(@cJson,'$.datos.fechaHasta')),
    @estado=JSON_VALUE(@cJson,'$.datos.estado'),
    @cantidad=TRY_CONVERT(DECIMAL(14,3),JSON_VALUE(@cJson,'$.datos.cantidadKg')),
    @observacion=NULLIF(LTRIM(RTRIM(JSON_VALUE(@cJson,'$.datos.observacion'))),N''),
    @versionEsperada=TRY_CONVERT(BIGINT,JSON_VALUE(@cJson,'$.datos.version'));
   IF @clave IS NULL OR @versionEsperada IS NULL OR @versionEsperada<0
    OR @fechaDesde IS NULL OR @fechaHasta IS NULL OR @fechaDesde>@fechaHasta
    OR YEAR(@fechaDesde)<>@anio OR YEAR(@fechaHasta)<>@anio
    OR @estado NOT IN('DISPONIBLE','PARCIAL','NO_DISPONIBLE') OR @estado IS NULL OR @cantidad IS NULL
    OR (@estado='NO_DISPONIBLE' AND @cantidad<>0)
    OR (@estado<>'NO_DISPONIBLE' AND @cantidad<=0)
    OR LEN(ISNULL(@observacion,N''))>400
    THROW 51803,N'Fechas, estado o kilos declarados no validos.',1;
   IF @estado<>'NO_DISPONIBLE' AND NOT EXISTS(
    SELECT 1 FROM prod.PlantaPaltaE3 P
    WHERE P.predio_id=@predio AND P.convenio_id=@conv AND P.uot_id=@uot
      AND P.estado_actual NOT IN('MUERTA','ELIMINADA'))
    THROW 51804,N'No hay plantas activas registradas en el fundo.',1;
   SET @hash=HASHBYTES('SHA2_256',CONCAT(@predio,N'|',@conv,N'|',@anio,N'|',JSON_QUERY(@cJson,'$.datos')));
   BEGIN TRANSACTION;
   -- Una sola fila de fundo se bloquea: serializa altas de un mismo año y permite reintentos.
   IF NOT EXISTS(SELECT 1 FROM prod.Predio WITH(UPDLOCK,HOLDLOCK) WHERE predio_id=@predio AND estado=1)
    THROW 51802,N'El fundo ya no esta activo.',1;
   SELECT @hashAnterior=hash_peticion,@respuestaAnterior=respuesta
    FROM prod.FundoProduccionSolicitudE3 WITH(UPDLOCK,HOLDLOCK)
    WHERE usuario_id=@usuario AND clave=@clave;
   IF @hashAnterior IS NOT NULL
   BEGIN
    IF @hashAnterior<>@hash THROW 51805,N'La clave de solicitud corresponde a otros datos.',1;
    COMMIT TRANSACTION;
    SELECT @cDatos=@respuestaAnterior,@bResultado=1,@cMensaje=N'Operacion ya registrada.',
     @cCodigoRespuesta='FUNDO_PRODUCCION_OK',@nHttpRespuesta=200;
    RETURN;
   END;
   SELECT @id=fundo_produccion_id,@versionActual=version,
    @antes=(SELECT F.estado_produccion estado,F.cantidad_disponible_kg cantidadKg,
     F.fecha_desde fechaDesde,F.fecha_hasta fechaHasta,F.observacion
     FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
   FROM prod.FundoProduccionE3 F WITH(UPDLOCK,HOLDLOCK)
   WHERE F.predio_id=@predio AND F.convenio_id=@conv AND F.anio=@anio;
   IF @versionEsperada<>@versionActual
    THROW 51806,N'La disponibilidad fue modificada. Actualice la ficha antes de guardar.',1;
   IF @id IS NULL
   BEGIN
    INSERT INTO prod.FundoProduccionE3
     (predio_id,uot_id,convenio_id,anio,fecha_desde,fecha_hasta,estado_produccion,cantidad_disponible_kg,observacion,usuario_id)
    VALUES(@predio,@uot,@conv,@anio,@fechaDesde,@fechaHasta,@estado,@cantidad,@observacion,@usuario);
    SET @id=CONVERT(BIGINT,SCOPE_IDENTITY());
   END
   ELSE
    UPDATE prod.FundoProduccionE3
    SET fecha_desde=@fechaDesde,fecha_hasta=@fechaHasta,estado_produccion=@estado,
     cantidad_disponible_kg=@cantidad,observacion=@observacion,usuario_id=@usuario,
     actualizado_en=SYSUTCDATETIME(),version=version+1
    WHERE fundo_produccion_id=@id AND uot_id=@uot;
   INSERT INTO prod.FundoProduccionHistorialE3(fundo_produccion_id,anterior,nuevo,usuario_id)
    VALUES(@id,@antes,JSON_QUERY(@cJson,'$.datos'),@usuario);
   -- Se calcula la respuesta y se almacena en la misma transaccion mas abajo.
  END;

  -- Universo acotado primero; no se recorre repetidamente el expediente individual.
  SELECT P.planta_id INTO #Plantas
  FROM prod.PlantaPaltaE3 P
  WHERE P.predio_id=@predio AND P.uot_id=@uot AND P.convenio_id=@conv
   AND P.estado_actual NOT IN('MUERTA','ELIMINADA');
  CREATE UNIQUE CLUSTERED INDEX IX_Plantas ON #Plantas(planta_id);
  SELECT R.planta_id,R.anio,R.produccion_id,R.tipo_registro,R.estimado_kg,R.real_kg
  INTO #Registros
  FROM prod.ProduccionPlantaE3 R
  JOIN #Plantas P ON P.planta_id=R.planta_id
  WHERE R.anio BETWEEN @anio-3 AND @anio;
  CREATE CLUSTERED INDEX IX_Registros ON #Registros(planta_id,anio,tipo_registro,produccion_id DESC);
  SELECT W.planta_id,W.anio,
   COALESCE(MAX(CASE WHEN W.tipo_registro='ESTIMACION' AND W.rn=1 THEN W.estimado_kg END),
            MAX(CASE WHEN W.tipo_registro='LEGADO' AND W.rn=1 THEN W.estimado_kg END)) estimado_kg,
   SUM(CASE WHEN W.tipo_registro='COSECHA' THEN ISNULL(W.real_kg,0) ELSE 0 END)
     +ISNULL(MAX(CASE WHEN W.tipo_registro='LEGADO' AND W.rn=1 THEN W.real_kg END),0) real_kg,
   MAX(CASE WHEN W.real_kg IS NOT NULL THEN 1 ELSE 0 END) tiene_real
  INTO #AnioPlanta
  FROM (SELECT R.*,
    ROW_NUMBER() OVER(PARTITION BY R.planta_id,R.anio,R.tipo_registro ORDER BY R.produccion_id DESC) rn
   FROM #Registros R) W
  GROUP BY W.planta_id,W.anio;
  CREATE UNIQUE CLUSTERED INDEX IX_AnioPlanta ON #AnioPlanta(planta_id,anio);
  SELECT planta_id,AVG(CONVERT(DECIMAL(19,3),real_kg)) historico_kg
  INTO #HistoricoPlanta FROM #AnioPlanta
  WHERE anio<@anio AND tiene_real=1 GROUP BY planta_id;
  CREATE UNIQUE CLUSTERED INDEX IX_HistoricoPlanta ON #HistoricoPlanta(planta_id);
  SELECT P.planta_id,A.estimado_kg,A.real_kg,A.tiene_real,H.historico_kg,
   CONVERT(DECIMAL(19,3),CASE
    WHEN A.estimado_kg IS NOT NULL AND H.historico_kg IS NOT NULL
      THEN (A.estimado_kg*0.7)+(H.historico_kg*0.3)
    WHEN A.estimado_kg IS NOT NULL THEN A.estimado_kg
    WHEN H.historico_kg IS NOT NULL THEN H.historico_kg
    WHEN A.tiene_real=1 THEN A.real_kg ELSE 0 END) proyectado_kg
  INTO #Proyeccion
  FROM #Plantas P
  LEFT JOIN #AnioPlanta A ON A.planta_id=P.planta_id AND A.anio=@anio
  LEFT JOIN #HistoricoPlanta H ON H.planta_id=P.planta_id;
  SELECT @plantas=COUNT_BIG(*),
   @conEstimacion=COALESCE(SUM(CASE WHEN estimado_kg IS NOT NULL THEN CONVERT(BIGINT,1) ELSE 0 END),0),
   @conCosecha=COALESCE(SUM(CASE WHEN tiene_real=1 THEN CONVERT(BIGINT,1) ELSE 0 END),0),
   @estPlantas=COALESCE(SUM(estimado_kg),0),@realPlantas=COALESCE(SUM(real_kg),0),
   @sugerido=COALESCE(SUM(proyectado_kg),0)
  FROM #Proyeccion;

  -- Entregas del fundo: no se duplican como cosechas de plantas ni se suman a ellas.
  SELECT YEAR(E.fecha_hora) anio,SUM(D.kilogramos) entregas_kg
  INTO #Ventas
  FROM comercial.EntregaSocio E
  JOIN comercial.EntregaDetalle D ON D.entrega_socio_id=E.entrega_socio_id AND D.estado=1
  JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id AND OS.estado=1
  JOIN comercial.OperativoVenta OV ON OV.operativo_venta_id=OS.operativo_venta_id AND OV.estado=1
  JOIN comercial.CampaniaVenta C ON C.campania_venta_id=OV.campania_venta_id AND C.uot_id=@uot
  WHERE E.predio_id=@predio AND E.estado=1 AND E.estado_proceso='CONFIRMADA'
    AND E.fecha_hora>=DATEFROMPARTS(@anio-3,1,1)
    AND E.fecha_hora<DATEFROMPARTS(@anio+1,1,1)
  GROUP BY YEAR(E.fecha_hora);
  CREATE UNIQUE CLUSTERED INDEX IX_Ventas ON #Ventas(anio);
  SELECT A.anio,
   COALESCE(SUM(A.estimado_kg),0) estimado_kg,COALESCE(SUM(A.real_kg),0) cosecha_kg
  INTO #Anual FROM #AnioPlanta A GROUP BY A.anio;
  CREATE UNIQUE CLUSTERED INDEX IX_Anual ON #Anual(anio);
  SELECT @mediaCosecha=COALESCE(AVG(CONVERT(DECIMAL(19,3),A.cosecha_kg)),0)
  FROM #Anual A WHERE A.anio<@anio AND A.cosecha_kg>0;
  SELECT @mediaVentas=COALESCE(AVG(CONVERT(DECIMAL(19,3),V.entregas_kg)),0)
  FROM #Ventas V WHERE V.anio<@anio AND V.entregas_kg>0;
  IF @sugerido>0
  BEGIN
   SET @origen=CASE WHEN @conEstimacion>0 AND EXISTS(SELECT 1 FROM #HistoricoPlanta) THEN 'PLANTAS_E_HISTORIAL'
    WHEN @conEstimacion>0 THEN 'ESTIMACION_POR_PLANTA' ELSE 'COSECHAS_POR_PLANTA' END;
   SET @calidad=CASE WHEN @plantas>0 AND @conEstimacion*2>=@plantas THEN 'ALTA' ELSE 'MEDIA' END;
  END
  ELSE IF @mediaVentas>0
  BEGIN SET @sugerido=@mediaVentas;SET @origen='ENTREGAS_HISTORICAS';SET @calidad='BAJA';END;
  IF @sugerido<@realPlantas SET @sugerido=@realPlantas;
  SELECT @estado=F.estado_produccion,@cantidad=F.cantidad_disponible_kg,@versionActual=F.version,
   @fechaDesde=F.fecha_desde,@fechaHasta=F.fecha_hasta,@observacion=F.observacion
  FROM prod.FundoProduccionE3 F
  WHERE F.predio_id=@predio AND F.convenio_id=@conv AND F.anio=@anio AND F.uot_id=@uot;
  SET @cDatos=(SELECT @predio predioId,@anio anio,@plantas plantasActivas,@conEstimacion plantasConEstimacion,
   @conCosecha plantasConCosecha,@estPlantas estimadoPlantasKg,@realPlantas cosechaPlantasKg,
   @mediaCosecha promedioCosechaHistoricaKg,@mediaVentas promedioEntregasHistoricasKg,
   @sugerido sugeridoKg,@origen fuenteSugerencia,@calidad calidadEstimacion,
   @estado estado,@cantidad cantidadKg,@versionActual version,CONVERT(VARCHAR(10),@fechaDesde,23) fechaDesde,
   CONVERT(VARCHAR(10),@fechaHasta,23) fechaHasta,@observacion observacion,
   (SELECT CONVERT(VARCHAR(19),F.actualizado_en,126) FROM prod.FundoProduccionE3 F
    WHERE F.predio_id=@predio AND F.convenio_id=@conv AND F.anio=@anio) actualizadoEn,
   JSON_QUERY((SELECT Y.anio,ISNULL(A.estimado_kg,0) estimadoPlantasKg,
     ISNULL(A.cosecha_kg,0) cosechaPlantasKg,ISNULL(V.entregas_kg,0) entregasKg
    FROM (VALUES(@anio),(@anio-1),(@anio-2),(@anio-3)) Y(anio)
    LEFT JOIN #Anual A ON A.anio=Y.anio LEFT JOIN #Ventas V ON V.anio=Y.anio
    ORDER BY Y.anio DESC FOR JSON PATH)) historial
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER,INCLUDE_NULL_VALUES);
  IF @cAccion='GUARDAR'
  BEGIN
   INSERT INTO prod.FundoProduccionSolicitudE3(usuario_id,clave,hash_peticion,respuesta)
    VALUES(@usuario,@clave,@hash,@cDatos);
   COMMIT TRANSACTION;
  END;
  SELECT @bResultado=1,@cMensaje=N'Produccion del fundo consultada.',
   @cCodigoRespuesta='FUNDO_PRODUCCION_OK',@nHttpRespuesta=200;
  DROP TABLE IF EXISTS #Ventas,#Anual,#Proyeccion,#HistoricoPlanta,#AnioPlanta,#Registros,#Plantas;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  DROP TABLE IF EXISTS #Ventas,#Anual,#Proyeccion,#HistoricoPlanta,#AnioPlanta,#Registros,#Plantas;
  SELECT @cDatos=NULL,@bResultado=0,
   @cMensaje=CASE WHEN ERROR_NUMBER() BETWEEN 51801 AND 51899 THEN ERROR_MESSAGE()
     ELSE N'No fue posible calcular la produccion del fundo.' END,
   @cCodigoRespuesta='FUNDO_PRODUCCION_ERROR',
   @nHttpRespuesta=CASE WHEN ERROR_NUMBER() BETWEEN 51801 AND 51899 THEN 400 ELSE 503 END;
 END CATCH;
END;
GO

-- Modificacion acotada al ultimo PA de activacion vigente (V654).
CREATE OR ALTER PROCEDURE [comercial].[PA_CampaniaVenta_Upd_Activar](@cJson NVARCHAR(MAX),@bResultado BIT OUTPUT,@cMensaje NVARCHAR(300) OUTPUT,
    @cCodigoRespuesta VARCHAR(60)=NULL OUTPUT,
    @nHttpRespuesta SMALLINT=NULL OUTPUT
)
AS
BEGIN
    SET @cMensaje=NULL; SET @cCodigoRespuesta=NULL; SET @nHttpRespuesta=NULL;

    /* Respuesta explícita; mensajes públicos aprobados. */
    SET NOCOUNT ON;
    DECLARE @__DbTranEntrada INT = @@TRANCOUNT,
            @__DbTranAbierta BIT = 0,
            @__DbSavepoint VARCHAR(32) = REPLACE(CONVERT(VARCHAR(36),NEWID()),'-',''),
            @__DbMensaje NVARCHAR(300),
            @__DbError BIT = 0;
    SET @bResultado = 0;
    SET ANSI_NULLS ON;
    SET ANSI_PADDING ON;
    SET ANSI_WARNINGS ON;
    SET ARITHABORT ON;
    SET CONCAT_NULL_YIELDS_NULL ON;
    SET NUMERIC_ROUNDABORT OFF;

    BEGIN TRY

 SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @nUsuario BIGINT,@nSesion BIGINT,@nDisp BIGINT,@nEmp BIGINT,@nModulo INT,@gCorr UNIQUEIDENTIFIER,@gSol UNIQUEIDENTIFIER,@cIp VARCHAR(64),@cEnd NVARCHAR(250),@nOp BIGINT,@bRep BIT,@cEstadoOp VARCHAR(20),@cIdRes NVARCHAR(200),@cCodRes VARCHAR(40),@bIni BIT,@cMsg NVARCHAR(300),@bFin BIT,@cMsgFin NVARCHAR(300),@nAud BIGINT,@nTrans BIGINT,@nUotSolicitada BIGINT,@nUot BIGINT,@bModoGeneral BIT,@bUot BIT,@cUotMsg NVARCHAR(300),@nId BIGINT,@cMotivo NVARCHAR(500),@cIdent NVARCHAR(200),@dInicio DATE,@dFin DATE,@nAsociacion BIGINT;
    SELECT @bResultado=0,@cMensaje=N'No se pudo completar la acción.';
    EXEC [seg].[PA_Operacion_Ins_IniciarIdempotente] @cJson=@cJson,@cCodigoPermiso='CAMPANIAS_CONFIRMAR|CAMPANIAS_APROBAR',@cAmbito='CAMPANIA_ACTIVAR',@nUsuarioId=@nUsuario OUTPUT,@nSesionUsuarioId=@nSesion OUTPUT,@nDispositivoUsuarioId=@nDisp OUTPUT,@nEmpleadoId=@nEmp OUTPUT,@nModuloId=@nModulo OUTPUT,@gCorrelacionId=@gCorr OUTPUT,@gSolicitudId=@gSol OUTPUT,@cIp=@cIp OUTPUT,@cEndpoint=@cEnd OUTPUT,@nOperacionIdempotenteId=@nOp OUTPUT,@bEsRepetida=@bRep OUTPUT,@cEstadoOperacion=@cEstadoOp OUTPUT,@cIdentificadorResultado=@cIdRes OUTPUT,@cCodigoResultado=@cCodRes OUTPUT,@bResultado=@bIni OUTPUT,@cMensaje=@cMsg OUTPUT;
    IF @bIni=0 AND @bRep=0 BEGIN SET @cMensaje=@cMsg;
GOTO __DESCO_Salida;
END;
    IF @bRep=1 BEGIN SET @bResultado=CASE WHEN @cEstadoOp='COMPLETADA' THEN 1 ELSE 0 END;
SET @cMensaje=CASE WHEN @cEstadoOp='COMPLETADA' THEN N'La solicitud ya fue procesada correctamente.' ELSE N'La solicitud ya se encuentra en proceso.' END;
GOTO __DESCO_Salida;
END;
SELECT @nId=campaniaVentaId,@nUotSolicitada=uotId,@cMotivo=NULLIF(LTRIM(RTRIM(motivo)),N'')
FROM OPENJSON(@cJson,'$.campania')
WITH(campaniaVentaId BIGINT '$.campaniaVentaId',uotId BIGINT '$.uotId',motivo NVARCHAR(500) '$.motivo');
IF @nUotSolicitada IS NULL SELECT @nUotSolicitada=uot_id FROM comercial.CampaniaVenta WHERE campania_venta_id=@nId;
EXEC seg.PA_UOT_Sel_ResolverContextoSesion @nUsuario,@nSesion,@nUotSolicitada,NULL,1,@nUot OUTPUT,@bModoGeneral OUTPUT,@bUot OUTPUT,@cUotMsg OUTPUT;
IF @bUot=0 BEGIN SET @cMensaje=@cUotMsg; GOTO Fallar; END;
IF seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_CONFIRMAR')<>1
   AND seg.FN_Usuario_TienePermisoUOT(@nUsuario,@nUot,'CAMPANIAS_APROBAR')<>1
BEGIN SET @cMensaje=N'No tiene permiso para activar la campaña en esta UOT.'; GOTO Fallar; END;
IF @nId IS NULL BEGIN SET @cMensaje=N'Seleccione una campaña.';
GOTO Fallar;
END;
SELECT @dInicio=fecha_inicio,@dFin=fecha_fin,@nAsociacion=asociacion_id
FROM comercial.CampaniaVenta
WHERE campania_venta_id=@nId AND uot_id=@nUot AND estado=1 AND estado_proceso='PLANIFICACION';
IF @nAsociacion IS NULL BEGIN SET @cMensaje=N'La campaña no se encuentra en un estado válido para activarla.';
GOTO Fallar;
END;
IF @dInicio IS NULL OR @dFin IS NULL OR @dFin<@dInicio
   OR @dFin<CONVERT(DATE,DATEADD(HOUR,-5,SYSUTCDATETIME()))
BEGIN SET @cMensaje=N'La campaña ya venció o tiene fechas inválidas. Corrija la vigencia antes de activarla.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.ParticipacionCampaniaSocio WHERE campania_venta_id=@nId AND estado=1 AND estado_participacion='ACTIVO')
BEGIN SET @cMensaje=N'Incluya al menos un socio antes de activar la campaña.';
GOTO Fallar;
END;
IF NOT EXISTS(SELECT 1 FROM comercial.PrecioComercial WHERE campania_venta_id=@nId AND estado=1 AND CONVERT(DATE,fecha_vigencia_desde)<=COALESCE(@dFin,@dInicio) AND (fecha_vigencia_hasta IS NULL OR CONVERT(DATE,fecha_vigencia_hasta)>=@dInicio))
BEGIN SET @cMensaje=N'Registre al menos un precio vigente antes de activar la campaña.';
GOTO Fallar;
END;
-- Un socio participa cuando al menos uno de sus fundos tiene disponibilidad declarada
-- para la campaña. El expediente por planta no constituye por si solo disponibilidad.
IF NOT EXISTS
(
 SELECT 1
 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id
  AND SA.asociacion_id=@nAsociacion AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
 JOIN prod.FundoProduccionE3 FP ON FP.predio_id=PT.predio_id AND FP.uot_id=@nUot
  AND FP.fecha_desde<=@dFin AND FP.fecha_hasta>=@dInicio
  AND FP.estado_produccion IN('DISPONIBLE','PARCIAL') AND FP.cantidad_disponible_kg>0
 JOIN org.ConvenioUOTOrganizacion CUO ON CUO.convenio_uot_organizacion_id=FP.convenio_id
  AND CUO.empresa_id=@nAsociacion AND CUO.uot_id=@nUot AND CUO.estado=1
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
   AND EXISTS(SELECT 1 FROM prod.PlantaPaltaE3 P
       WHERE P.predio_id=FP.predio_id AND P.convenio_id=FP.convenio_id
        AND P.uot_id=@nUot AND P.estado_actual NOT IN('MUERTA','ELIMINADA'))
)
AND NOT EXISTS
(
 -- Compatibilidad con declaraciones anteriores a la nueva ficha del fundo.
 SELECT 1 FROM comercial.ParticipacionCampaniaSocio PCS
 JOIN org.SocioAsociacion SA ON SA.socio_asociacion_id=PCS.socio_asociacion_id AND SA.estado=1
 JOIN prod.PredioTitularidad PT ON PT.socio_id=SA.socio_id AND PT.estado=1
 JOIN prod.Parcela P ON P.predio_id=PT.predio_id AND P.estado=1
 JOIN prod.ParcelaCultivo PC ON PC.parcela_id=P.parcela_id
  AND PC.estado=1 AND PC.situacion_cultivo='ACTIVO'
 JOIN prod.DisponibilidadProduccion DP ON DP.parcela_cultivo_id=PC.parcela_cultivo_id
  AND DP.estado=1 AND DP.estado_estimacion IN('ESTIMADA','CONFIRMADA')
 WHERE PCS.campania_venta_id=@nId AND PCS.estado=1 AND PCS.estado_participacion='ACTIVO'
  AND SA.asociacion_id=@nAsociacion
  AND PT.fecha_desde<=@dFin AND (PT.fecha_hasta IS NULL OR PT.fecha_hasta>=@dInicio)
  AND DP.cantidad_estimada_kg>0
  AND DP.disponible_desde<=@dFin AND (DP.disponible_hasta IS NULL OR DP.disponible_hasta>=@dInicio)
)
BEGIN
 SET @cMensaje=N'No hay producción disponible de los participantes para las fechas de la campaña.';
 GOTO Fallar;
END;
BEGIN TRY BEGIN
    IF @__DbTranEntrada = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION @__DbSavepoint;
    SET @__DbTranAbierta = 1;
END;
UPDATE comercial.CampaniaVenta SET estado_proceso='ACTIVA' WHERE campania_venta_id=@nId AND uot_id=@nUot;
SET @cIdent=CONVERT(NVARCHAR(200),@nId);
EXEC auditoria.PA_Operacion_Ins_RegistrarCambio @nUsuario,@nSesion,@nDisp,@nModulo,'ACTIVA','comercial','CampaniaVenta',@cIdent,NULL,NULL,@cMotivo,'estado_proceso','PLANIFICACION','ACTIVA',@cIp,@gCorr,@gSol,@cEnd,@nAud OUTPUT,@nTrans OUTPUT;
/* Confirmar datos e idempotencia juntos. */EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='COMPLETADA',@cEsquemaEntidad='comercial',@cNombreEntidad='CampaniaVenta',@cIdentificadorResultado=@cIdent,@cCodigoResultado='CAMPANIA_ACTIVA',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;
IF ISNULL(@bFin,0) = 0
    THROW 51003, N'DESCO_IDEMPOTENCIA_NO_CERRADA', 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 COMMIT TRANSACTION;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado=1;
SET @cMensaje=N'Campaña activada.';
GOTO __DESCO_Salida;
 END TRY BEGIN CATCH
SET @bResultado = 0;
 IF XACT_STATE()<>0 BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @cMensaje=N'No se pudo completar la acción. Intente nuevamente.';
IF ISNULL(@bResultado,0) = 0
BEGIN
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END;
END CATCH;
Fallar:
    IF @nOp IS NOT NULL AND @bResultado=0 EXEC [auditoria].[PA_OperacionIdempotente_Upd_Finalizar] @nOperacionIdempotenteId=@nOp,@cEstadoOperacion='FALLIDA',@cEsquemaEntidad=NULL,@cNombreEntidad=NULL,@cIdentificadorResultado=NULL,@cCodigoResultado='NO_PROCESADO',@bResultado=@bFin OUTPUT,@cMensaje=@cMsgFin OUTPUT;

    END TRY
    BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
    END CATCH;

__DESCO_Salida:
BEGIN TRY

IF @__DbTranAbierta = 1
BEGIN
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
IF ISNULL(@bResultado,0) = 1 OR NULLIF(@cMensaje,N'') IS NULL SET @cMensaje = N'La operación no se completó y sus cambios fueron revertidos.';
SET @bResultado = 0;
END;

    IF @bResultado = 0 AND @nOp IS NOT NULL AND XACT_STATE() <> -1
    BEGIN
        IF ISNULL(@bRep,0) = 0
        BEGIN
        BEGIN TRY
            EXEC [auditoria].[PA_OperacionIdempotente_Upd_MensajeFallido]
                 @nOperacionIdempotenteId = @nOp, @cMensajeResultado = @cMensaje;
        END TRY
        BEGIN CATCH
            -- No sustituir el motivo funcional por un fallo de registro secundario.
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @__DbMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
        END CATCH;
        END
        ELSE
        BEGIN
            SELECT @cMensaje = COALESCE(mensaje_resultado,
                CASE WHEN estado_operacion = 'FALLIDA'
                     THEN N'La solicitud anterior no se completó. Corrija los datos y envíe una nueva solicitud.'
                     ELSE N'La solicitud todavía se está procesando. Consulte el resultado antes de repetirla.' END)
            FROM [auditoria].[OperacionIdempotente]
            WHERE operacion_idempotente_id = @nOp;
        END;
    END;

END TRY
BEGIN CATCH

        SET @__DbError = 1;
BEGIN
    IF @__DbTranAbierta = 1
    BEGIN
        IF @__DbTranEntrada = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @__DbTranEntrada > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION @__DbSavepoint;
        SET @__DbTranAbierta = 0;
    END;
END;
SET @bResultado = 0;
EXEC [config].[PA_Respuesta_ResolverError]
    @cProcedimiento = N'comercial.PA_CampaniaVenta_Upd_Activar',
    @cMensaje = @cMensaje OUTPUT,
    @cJson = @cJson,
    @bMensajePublicoGenerico = 0;
END CATCH;
IF XACT_STATE() = -1 AND ISNULL(@bResultado,0) = 1
BEGIN
SET @bResultado = 0;
SET @cMensaje = N'La transacción no puede confirmarse. Vuelva a iniciar la solicitud.';
END;
SET @bResultado=ISNULL(@bResultado,0);
SELECT @cMensaje=R.mensaje,@cCodigoRespuesta=R.codigo,@nHttpRespuesta=R.http_sugerido
FROM config.FN_RespuestaUsuario(N'comercial.PA_CampaniaVenta_Upd_Activar',@bResultado,@cMensaje) R;
IF @bResultado=1 RETURN 0;
RETURN 1;
END;
GO
