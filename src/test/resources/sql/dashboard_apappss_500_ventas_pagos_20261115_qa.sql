-- DESCO / APAPPSS / INVESTIGACION HTTP 500 VENTAS Y PAGOS - 2026-11-15
-- SQL Server. SOLO LECTURA: no UPDATE, DELETE ni INSERT en datos de negocio.
-- 1) Ejecutar en la MISMA BASE de datos a la que se conecta Spring Boot.
-- 2) Revisar errores originales, aplicación real de Flyway y el PA activo.
-- 3) Repetir el HTTP 500 y ejecutar nuevamente para identificar el paso exacto.
SET NOCOUNT ON;
DECLARE @ConvenioId BIGINT=2,@Desde DATE='2025-11-15',@Hasta DATE='2026-11-15';
DECLARE @SesionPublicaId UNIQUEIDENTIFIER=NULL; -- Opcional. Sesión pública real vigente de DEV.
DECLARE @EjecutarPA BIT=0; -- 0: solo auditoría y verificaciones; 1: ejecuta el PA de consulta.

SELECT DB_NAME() AS base_actual, @@SERVERNAME AS servidor, SYSDATETIME() AS servidor_fecha,
       OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P') AS pa_id,
       COL_LENGTH(N'auditoria.ErrorBaseDatos',N'mensaje_sql') AS hay_mensaje_sql,
       COL_LENGTH(N'auditoria.ErrorBaseDatos',N'diagnostico_etapa') AS hay_etapa;

IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
BEGIN
    EXEC(N'SELECT installed_rank,version,description,success,installed_on
           FROM dbo.flyway_schema_history
           WHERE version IN (''690'',''691'',''692'') ORDER BY installed_rank');
END;

-- Comprobar la definición REAL en BD, no solo la copia en el .md exportado.
SELECT CASE
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P')) LIKE N'%diagnostico_etapa%'
      THEN N'PA V692 detectado'
    WHEN OBJECT_DEFINITION(OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P')) LIKE N'%@errMensaje%'
      THEN N'PA V691 detectado'
    ELSE N'PA ANTERIOR o definición no visible: revisar permisos / Flyway'
    END AS version_pa_observada;

IF OBJECT_ID(N'auditoria.ErrorBaseDatos',N'U') IS NOT NULL
BEGIN
    DECLARE @Sql NVARCHAR(MAX)=N'SELECT TOP(50) fecha_utc,correlacion_id,numero_error,procedimiento,linea,codigo'
        +CASE WHEN COL_LENGTH(N'auditoria.ErrorBaseDatos',N'tab') IS NOT NULL THEN N',tab' ELSE N'' END
        +CASE WHEN COL_LENGTH(N'auditoria.ErrorBaseDatos',N'mensaje_sql') IS NOT NULL THEN N',mensaje_sql' ELSE N'' END
        +CASE WHEN COL_LENGTH(N'auditoria.ErrorBaseDatos',N'diagnostico_etapa') IS NOT NULL THEN N',diagnostico_etapa' ELSE N'' END
        +N' FROM auditoria.ErrorBaseDatos WHERE codigo=''APAPPSS_DASHBOARD'' OR correlacion_id IN ('
        +N'''d701eeca-e073-4b28-9725-d2cf6d3e917f'','
        +N'''779da971-667f-4506-8837-66bfff8a7118'','
        +N'''b474607d-f935-4b3a-9d13-ee92691f76c3'','
        +N'''c81685fd-bee8-416a-8179-aadf58d242fd'','
        +N'''6c4ab6ca-aca8-4d86-bcc7-245cf7f94555'') ORDER BY fecha_utc DESC;';
    EXEC sys.sp_executesql @Sql;
END;

-- Esquema de las fuentes de VENTAS y PAGOS: detecta tablas faltantes.
SELECT V.tabla,OBJECT_ID(V.tabla,N'U') AS objeto
FROM (VALUES(N'comercial.EntregaSocio'),(N'comercial.OperativoSocio'),
(N'comercial.OperativoVenta'),(N'comercial.CampaniaVenta'),
(N'finanzas.PagoSocio'),(N'finanzas.LiquidacionSocio'),
(N'comercial.ParticipacionCampaniaSocio'),(N'org.ConvenioUOTOrganizacion')) V(tabla);

-- Prueba aislada de SQL de ventas, sin dependencia de la sesión JWT.
BEGIN TRY
    SELECT N'VENTAS_ENTREGAS' AS prueba,COUNT_BIG(*) AS valor
    FROM comercial.EntregaSocio E
    JOIN comercial.OperativoSocio OS ON OS.operativo_socio_id=E.operativo_socio_id
    JOIN comercial.OperativoVenta O ON O.operativo_venta_id=OS.operativo_venta_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=O.campania_venta_id
    WHERE E.estado=1 AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion
      WHERE convenio_uot_organizacion_id=@ConvenioId)
      AND E.fecha_hora>=@Desde AND E.fecha_hora<DATEADD(DAY,1,CONVERT(DATETIME2(0),@Hasta));
END TRY BEGIN CATCH
    SELECT N'VENTAS_ENTREGAS' AS prueba,ERROR_NUMBER() AS numero_error,
           ERROR_LINE() AS linea,ERROR_MESSAGE() AS error_sql;
END CATCH;

BEGIN TRY
    SELECT N'PAGOS_ABONADO' AS prueba,COALESCE(SUM(P.importe),0) AS valor
    FROM finanzas.PagoSocio P
    JOIN finanzas.LiquidacionSocio L ON L.liquidacion_socio_id=P.liquidacion_socio_id
    JOIN comercial.ParticipacionCampaniaSocio S ON S.participacion_campania_socio_id=L.participacion_campania_socio_id
    JOIN comercial.CampaniaVenta C ON C.campania_venta_id=S.campania_venta_id
    WHERE P.estado=1 AND P.estado_proceso<>'ANULADO'
      AND C.asociacion_id=(SELECT empresa_id FROM org.ConvenioUOTOrganizacion
      WHERE convenio_uot_organizacion_id=@ConvenioId)
      AND P.fecha_hora>=@Desde AND P.fecha_hora<DATEADD(DAY,1,CONVERT(DATETIME2(0),@Hasta));
END TRY BEGIN CATCH
    SELECT N'PAGOS_ABONADO' AS prueba,ERROR_NUMBER() AS numero_error,
           ERROR_LINE() AS linea,ERROR_MESSAGE() AS error_sql;
END CATCH;

-- Ejecución opcional del PA, usando una sesión REAL del mismo ámbito, no una ficticia.
IF @EjecutarPA=1
BEGIN
 IF @SesionPublicaId IS NULL
    THROW 51694,N'Para ejecutar el procedimiento debe proporcionar una sesión pública real de DEV.',1;
 DECLARE @Tab VARCHAR(20),@Json NVARCHAR(MAX),@Respuesta NVARCHAR(MAX),
 @Exitoso BIT,@Mensaje NVARCHAR(300),@Http SMALLINT,@Corr UNIQUEIDENTIFIER;
 DECLARE @Resultado TABLE(tab VARCHAR(20),correlacion_id UNIQUEIDENTIFIER,
 exitoso BIT,http SMALLINT,mensaje NVARCHAR(300),indicadores INT,puntos INT);
 DECLARE C CURSOR LOCAL FAST_FORWARD FOR SELECT tab FROM (VALUES('VENTAS'),('PAGOS')) T(tab);
 OPEN C;FETCH NEXT FROM C INTO @Tab;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @Corr=NEWID();
  SET @Json=(SELECT JSON_QUERY((SELECT @SesionPublicaId sesionPublicaId,
   @Corr correlacionId,NEWID() solicitudId,N'127.0.0.1' ip,
   N'/api/v1/reportes/apappss/resumen' endpoint,N'Dashboard-QA' userAgent,
   N'Dashboard-QA' deviceId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) contexto,
   JSON_QUERY((SELECT @Tab tab,@Desde desde,@Hasta hasta,@ConvenioId convenioId
    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) filtros FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  BEGIN TRY
   EXEC reporte.PA_Apappss_Analytics @cAccion='RESUMEN',@cJson=@Json,
    @cDatos=@Respuesta OUTPUT,@bResultado=@Exitoso OUTPUT,
    @cMensaje=@Mensaje OUTPUT,@nHttp=@Http OUTPUT;
   INSERT @Resultado SELECT @Tab,@Corr,@Exitoso,@Http,@Mensaje,
     (SELECT COUNT(*) FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END,'$.indicadores')),
     (SELECT COUNT(*) FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END,'$.puntos'));
  END TRY BEGIN CATCH
   INSERT @Resultado(tab,correlacion_id,exitoso,http,mensaje)
    VALUES(@Tab,@Corr,0,500,CONCAT(ERROR_NUMBER(),N': ',ERROR_MESSAGE()));
  END CATCH;
  FETCH NEXT FROM C INTO @Tab;
 END;
 CLOSE C;DEALLOCATE C;
 SELECT *,CASE WHEN exitoso=1 AND http=200 AND indicadores=4 THEN N'OK' ELSE N'REVISAR' END resultado
 FROM @Resultado;
END;
