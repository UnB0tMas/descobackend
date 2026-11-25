-- QA Dashboard APAPPSS / V690 - 15-11-2026. LECTURA inicial; activacion voluntaria de EXEC.
-- No crea ni cambia datos de negocio. El PA puede generar una entrada de auditoria en su CATCH.
-- Probar en DEV con un usuario/sesion ADMINISTRADOR valido y convenio UOT real.
DECLARE @UsuarioLogin VARCHAR(80) = 'administrador'; -- Reemplazar por login real
DECLARE @UotId BIGINT = NULL; -- UOT activa en pantalla
DECLARE @ConvenioId BIGINT = NULL; -- convenio realmente seleccionado
DECLARE @EjecutarPA BIT = 0; -- 0=solo inspeccion, 1=ejecutar las siete pestañas
DECLARE @Hoy DATE = CONVERT(DATE,(SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'SA Pacific Standard Time');
DECLARE @Desde DATE = DATEADD(DAY,-365,@Hoy);
DECLARE @Hasta DATE = @Hoy;

-- Verificar versiones 688, 689 y 690 sin editar flyway_schema_history.
IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
 EXEC(N'SELECT installed_rank,version,description,success FROM dbo.flyway_schema_history WHERE version IN (''685'',''686'',''687'',''688'',''689'',''690'') ORDER BY installed_rank');

-- La version 688 se reserva a Gestion Comercial; 689 a Gestion Documentaria;
-- V690 al Dashboard APAPPSS. Confirmar contra el historial antes de probar el PA.
IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
 EXEC(N'SELECT version,description,script,success FROM dbo.flyway_schema_history WHERE version IN (''688'',''689'',''690'') ORDER BY installed_rank');

SELECT N'PA actual' AS objeto,OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P') AS object_id,
       CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P')) LIKE N'%Contrato incompleto del dashboard APAPPSS%'
            THEN N'Contrato dashboard presente' ELSE N'Contrato dashboard ausente' END AS revision;

IF @UotId IS NULL OR @ConvenioId IS NULL
BEGIN
 SELECT N'COMPLETAR @UotId Y @ConvenioId PARA DIAGNOSTICO DE DATOS' AS aviso;
 RETURN;
END;
IF NOT EXISTS (SELECT 1 FROM org.ConvenioUOTOrganizacion
               WHERE convenio_uot_organizacion_id=@ConvenioId AND uot_id=@UotId AND estado=1)
 THROW 51080,N'Convenio no vigente o no pertenece a la UOT indicada.',1;
DECLARE @EmpresaId BIGINT=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion WHERE convenio_uot_organizacion_id=@ConvenioId);
DECLARE @Inicio DATETIME2(0)=CONVERT(DATETIME2(0),CAST(@Desde AS DATETIME2(0)) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');
DECLARE @Fin DATETIME2(0)=CONVERT(DATETIME2(0),DATEADD(DAY,1,CAST(@Hasta AS DATETIME2(0))) AT TIME ZONE 'SA Pacific Standard Time' AT TIME ZONE 'UTC');

-- Los siguientes SELECT distinguen datos históricos de datos dentro del filtro.
SELECT N'SOCIOS' seccion,COUNT_BIG(DISTINCT S.socio_id) total FROM org.SocioAsociacion S
 JOIN org.Asociacion A ON A.asociacion_id=S.asociacion_id
 WHERE A.uot_id=@UotId AND A.asociacion_id=@EmpresaId AND S.estado=1;
SELECT N'VENTAS' seccion,COUNT_BIG(*) total, SUM(CASE WHEN E.fecha_hora>=@Inicio AND E.fecha_hora<@Fin THEN 1 ELSE 0 END) en_periodo
 FROM comercial.EntregaSocio E
 JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
 JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
 WHERE E.estado=1 AND C.uot_id=@UotId AND C.asociacion_id=@EmpresaId;
SELECT N'PAGOS' seccion,COUNT_BIG(*) total, SUM(CASE WHEN PS.fecha_hora>=@Inicio AND PS.fecha_hora<@Fin THEN 1 ELSE 0 END) en_periodo
 FROM finanzas.PagoSocio PS
 JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=PS.liquidacion_socio_id
 JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id
 JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id
 WHERE PS.estado=1 AND C.uot_id=@UotId AND C.asociacion_id=@EmpresaId;
SELECT C.campania_venta_id,C.nombre,C.fecha_inicio,
 (SELECT COUNT_BIG(*) FROM comercial.OperativoVenta O WHERE O.campania_venta_id=C.campania_venta_id AND O.estado=1) operativos
 FROM comercial.CampaniaVenta C WHERE C.uot_id=@UotId AND C.asociacion_id=@EmpresaId AND C.estado=1
 ORDER BY C.fecha_inicio DESC;
SELECT COUNT_BIG(*) plantas_activas,
 SUM(CASE WHEN P.creado_en>=@Inicio AND P.creado_en<@Fin THEN 1 ELSE 0 END) plantas_en_periodo
 FROM prod.PlantaPaltaE3 P WHERE P.uot_id=@UotId AND P.convenio_id=@ConvenioId AND P.activo=1;

-- Graficos sin datos: diferenciar cero registros del intervalo vs. error de consulta.
SELECT N'CAMPANIAS_FECHAS' AS grafico,
 COUNT_BIG(*) AS registros_total,
 COALESCE(SUM(CASE WHEN C.fecha_inicio BETWEEN @Desde AND @Hasta THEN CONVERT(BIGINT,1) ELSE CONVERT(BIGINT,0) END),0) AS registros_periodo
FROM comercial.CampaniaVenta C
WHERE C.uot_id=@UotId AND C.asociacion_id=@EmpresaId AND C.estado=1;
SELECT N'CAMPANIAS_OPERATIVOS' AS grafico,COUNT_BIG(*) AS registros_total
FROM comercial.OperativoVenta O
JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
WHERE C.uot_id=@UotId AND C.asociacion_id=@EmpresaId AND C.estado=1 AND O.estado=1;
SELECT N'PREDIOS_REGISTRO_PLANTA' AS grafico,COUNT_BIG(*) AS registros_total,
 COALESCE(SUM(CASE WHEN P.creado_en>=@Inicio AND P.creado_en<@Fin THEN CONVERT(BIGINT,1) ELSE CONVERT(BIGINT,0) END),0) AS registros_periodo
FROM prod.PlantaPaltaE3 P
WHERE P.uot_id=@UotId AND P.convenio_id=@ConvenioId AND P.activo=1;

-- Comprobar permiso efectivo para las tres pestañas que fallan.
SELECT P.codigo,seg.FN_Usuario_TienePermisoUOT(U.usuario_id,@UotId,P.codigo) permitido
 FROM seg.Usuario U CROSS JOIN seg.Permiso P
 WHERE U.nombre_usuario=@UsuarioLogin AND P.codigo IN
 ('REPORTES_CONTROL_VER','DASHBOARD_APAPPSS_VER','APAPPSS_SOCIOS_LISTAR',
 'APAPPSS_PREDIOS_LISTAR','CAMPANIAS_LISTAR','ENTREGAS_LISTAR','COMPRADORES_LISTAR',
 'LIQUIDACIONES_LISTAR','PAGOS_LISTAR')
 ORDER BY P.codigo;

-- Solo si se quiere probar el contrato real: establecer @EjecutarPA=1.
IF @EjecutarPA<>1 RETURN;
DECLARE @SesionPublicaId UNIQUEIDENTIFIER=(
 SELECT TOP(1) S.sesion_publica_id FROM seg.SesionUsuario S
 JOIN seg.Usuario U ON U.usuario_id=S.usuario_id
 WHERE U.nombre_usuario=@UsuarioLogin AND S.uot_contexto_id=@UotId AND S.modo_uot='ESPECIFICA'
 AND S.estado=1 AND S.fecha_revocacion IS NULL
 ORDER BY S.fecha_ultima_actividad DESC);
IF @SesionPublicaId IS NULL THROW 51081,N'No hay sesion activa compatible con usuario/UOT.',1;
DECLARE @Resultados TABLE(tab VARCHAR(20),exitoso BIT,http SMALLINT,mensaje NVARCHAR(300),
 indicadores INT,puntos INT,tipo_indicadores NVARCHAR(40),tipo_puntos NVARCHAR(40));
DECLARE @Tab VARCHAR(20),@Json NVARCHAR(MAX),@Respuesta NVARCHAR(MAX),@Exitoso BIT,@Mensaje NVARCHAR(300),@Http SMALLINT;
DECLARE panel CURSOR LOCAL FAST_FORWARD FOR
 SELECT tab FROM (VALUES('SOCIOS'),('PREDIOS'),('CAMPANIAS'),('VENTAS'),('COMPRADORES'),('LIQUIDACIONES'),('PAGOS')) P(tab);
OPEN panel;
FETCH NEXT FROM panel INTO @Tab;
WHILE @@FETCH_STATUS=0
BEGIN
 BEGIN TRY
  SET @Json=(SELECT JSON_QUERY((SELECT @SesionPublicaId sesionPublicaId,
    NEWID() correlacionId,NEWID() solicitudId,N'127.0.0.1' ip,N'/api/v1/reportes/apappss/resumen' endpoint,
    N'Dashboard-QA' userAgent,N'Dashboard-QA' deviceId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) contexto,
    JSON_QUERY((SELECT @Tab tab,@Desde desde,@Hasta hasta,@ConvenioId convenioId
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) filtros FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  EXEC reporte.PA_Apappss_Analytics @cAccion='RESUMEN',@cJson=@Json,
   @cDatos=@Respuesta OUTPUT,@bResultado=@Exitoso OUTPUT,@cMensaje=@Mensaje OUTPUT,@nHttp=@Http OUTPUT;
  INSERT @Resultados SELECT @Tab,@Exitoso,@Http,@Mensaje,
    (SELECT COUNT(*) FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END,'$.indicadores')),
    (SELECT COUNT(*) FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END,'$.puntos')),
    (SELECT [type] FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END) WHERE [key]='indicadores'),
    (SELECT [type] FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END) WHERE [key]='puntos');
 END TRY BEGIN CATCH
  INSERT @Resultados(tab,exitoso,http,mensaje) VALUES(@Tab,0,500,CONCAT(ERROR_NUMBER(),N': ',ERROR_MESSAGE()));
 END CATCH;
 FETCH NEXT FROM panel INTO @Tab;
END;
CLOSE panel;DEALLOCATE panel;
SELECT tab,exitoso,http,mensaje,indicadores,puntos,tipo_indicadores,tipo_puntos,
 CASE WHEN exitoso=1 AND indicadores=4 AND tipo_indicadores='4' AND tipo_puntos='4'
 THEN 'OK' ELSE 'REVISAR' END diagnostico FROM @Resultados;
SELECT TOP (20) fecha_utc,numero_error,procedimiento,linea,codigo,correlacion_id
FROM auditoria.ErrorBaseDatos WHERE codigo='APAPPSS_DASHBOARD' ORDER BY fecha_utc DESC;
