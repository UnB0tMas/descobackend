-- Diagnóstico APAPPSS, DEV/QA. Solo SELECT, salvo al activar @EjecutarPA=1.
-- El procedimiento en modo de prueba solo consulta datos; si falla, registra auditoría.
-- Los IDs fueron tomados de los errores HTTP 500 del 15-11-2026.
SET NOCOUNT ON;
DECLARE @ConvenioId BIGINT=2;
DECLARE @Desde DATE='2025-11-15', @Hasta DATE='2026-11-15';
DECLARE @SesionPublicaId UNIQUEIDENTIFIER=NULL; -- Solo completar con una sesión vigente de DEV.
DECLARE @EjecutarPA BIT=0; -- Activar en DEV/QA tras revisar diagnóstico.

SELECT E.fecha_utc,E.correlacion_id,E.numero_error,E.procedimiento,E.linea,
       E.codigo,E.tab,E.mensaje_sql
FROM auditoria.ErrorBaseDatos E
WHERE E.correlacion_id IN (
 'd701eeca-e073-4b28-9725-d2cf6d3e917f',
 '779da971-667f-4506-8837-66bfff8a7118',
 'b474607d-f935-4b3a-9d13-ee92691f76c3'
)
ORDER BY E.fecha_utc DESC;

-- Los registros anteriores a V691 no tienen mensaje_sql ni tab; número y línea
-- siguen disponibles si los errores se guardaron en la misma BD del servidor.
SELECT TOP(20) fecha_utc,correlacion_id,numero_error,procedimiento,linea,codigo,tab,mensaje_sql
FROM auditoria.ErrorBaseDatos
WHERE codigo='APAPPSS_DASHBOARD'
ORDER BY fecha_utc DESC;

SELECT OBJECT_ID(N'reporte.PA_Apappss_Analytics',N'P') AS procedimiento_id,
       OBJECT_ID(N'comercial.EntregaSocio',N'U') AS entregas_id,
       OBJECT_ID(N'comercial.OperativoSocio',N'U') AS operativo_socio_id,
       OBJECT_ID(N'comercial.OperativoVenta',N'U') AS operativo_venta_id,
       OBJECT_ID(N'finanzas.PagoSocio',N'U') AS pagos_id,
       OBJECT_ID(N'finanzas.LiquidacionSocio',N'U') AS liquidaciones_id;

IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
    EXEC(N'SELECT installed_rank,version,description,success
           FROM dbo.flyway_schema_history
           WHERE version IN (''690'',''691'') ORDER BY installed_rank');

IF @EjecutarPA<>1 RETURN;
IF @SesionPublicaId IS NULL
    THROW 51692,N'Indique una sesión pública vigente antes de ejecutar el PA.',1;

DECLARE @Tab VARCHAR(20),@Json NVARCHAR(MAX),@Respuesta NVARCHAR(MAX),
        @Exitoso BIT,@Mensaje NVARCHAR(300),@Http SMALLINT,@Correlacion UNIQUEIDENTIFIER;
DECLARE @Resultado TABLE(tab VARCHAR(20),correlacion_id UNIQUEIDENTIFIER,exitoso BIT,
                       http SMALLINT,mensaje NVARCHAR(300),indicadores INT,tipo_puntos INT);
DECLARE panel CURSOR LOCAL FAST_FORWARD FOR SELECT tab FROM (VALUES('VENTAS'),('PAGOS')) S(tab);
OPEN panel;
FETCH NEXT FROM panel INTO @Tab;
WHILE @@FETCH_STATUS=0
BEGIN
    SET @Correlacion=NEWID();
    SET @Json=(SELECT JSON_QUERY((SELECT @SesionPublicaId sesionPublicaId,
       @Correlacion correlacionId,NEWID() solicitudId,N'127.0.0.1' ip,
       N'/api/v1/reportes/apappss/resumen' endpoint,N'Dashboard-QA' userAgent,
       N'Dashboard-QA' deviceId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) contexto,
       JSON_QUERY((SELECT @Tab tab,@Desde desde,@Hasta hasta,@ConvenioId convenioId
         FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) filtros FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
    BEGIN TRY
        EXEC reporte.PA_Apappss_Analytics @cAccion='RESUMEN',@cJson=@Json,
             @cDatos=@Respuesta OUTPUT,@bResultado=@Exitoso OUTPUT,
             @cMensaje=@Mensaje OUTPUT,@nHttp=@Http OUTPUT;
        INSERT @Resultado VALUES(@Tab,@Correlacion,@Exitoso,@Http,@Mensaje,
             (SELECT COUNT(*) FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END,'$.indicadores')),
             (SELECT [type] FROM OPENJSON(CASE WHEN ISJSON(@Respuesta)=1 THEN @Respuesta ELSE N'{}' END) WHERE [key]='puntos'));
    END TRY BEGIN CATCH
        INSERT @Resultado(tab,correlacion_id,exitoso,http,mensaje)
        VALUES(@Tab,@Correlacion,0,500,CONCAT(ERROR_NUMBER(),N': ',ERROR_MESSAGE()));
    END CATCH;
    FETCH NEXT FROM panel INTO @Tab;
END;
CLOSE panel;DEALLOCATE panel;
SELECT *,CASE WHEN exitoso=1 AND http=200 AND indicadores=4 AND tipo_puntos=4
       THEN 'OK' ELSE 'REVISAR' END AS diagnostico FROM @Resultado;
SELECT E.fecha_utc,E.correlacion_id,E.numero_error,E.procedimiento,E.linea,E.tab,E.mensaje_sql
FROM auditoria.ErrorBaseDatos E JOIN @Resultado R ON R.correlacion_id=E.correlacion_id;
