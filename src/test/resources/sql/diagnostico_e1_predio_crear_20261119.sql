-- Diagnóstico del alta en DEV: no modifica registros.
-- Ejecutar en la base DESCO del entorno de desarrollo.
SET NOCOUNT ON;
DECLARE @correlacion UNIQUEIDENTIFIER = '7e81bbda-0858-4f0f-af81-47c439f5cb7e';

SELECT DB_NAME() AS base_actual;
IF OBJECT_ID(N'auditoria.ExpedienteErrorTecnico',N'U') IS NOT NULL
BEGIN
    SELECT TOP (10)
        E.fecha_utc, E.correlacion_id, E.operacion, E.numero_sql,
        E.procedimiento, E.linea_sql, E.mensaje_sql
    FROM auditoria.ExpedienteErrorTecnico E WITH (NOLOCK)
    WHERE E.correlacion_id = @correlacion
    ORDER BY E.error_id DESC;

    SELECT TOP (5)
        E.fecha_utc, E.correlacion_id, E.operacion, E.numero_sql,
        E.procedimiento, E.linea_sql, E.mensaje_sql
    FROM auditoria.ExpedienteErrorTecnico E WITH (NOLOCK)
    WHERE E.operacion = 'PREDIO_CREAR'
    ORDER BY E.error_id DESC;
END;

SELECT OBJECT_SCHEMA_NAME(P.object_id) AS esquema, P.name,
       P.modify_date
FROM sys.procedures P WITH (NOLOCK)
WHERE P.object_id IN
    (OBJECT_ID(N'prod.PA_ExpedienteProductivo_Ejecutar'),
     OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar'),
     OBJECT_ID(N'geo.PA_Ubicacion_Ins_Interna'));

SELECT O.name, S.name AS esquema, O.type_desc
FROM sys.objects O WITH (NOLOCK)
JOIN sys.schemas S WITH (NOLOCK) ON S.schema_id = O.schema_id
WHERE (S.name = N'prod' AND O.name = N'SQ_CodigoPredio')
   OR (S.name = N'auditoria' AND O.name = N'ExpedienteErrorTecnico');

IF OBJECT_ID(N'dbo.flyway_schema_history', N'U') IS NOT NULL
BEGIN
    SELECT V.installed_rank, V.version, V.description, V.success
    FROM dbo.flyway_schema_history V WITH (NOLOCK)
    WHERE V.version IN ('651','652','653','654','655','656','657','658')
    ORDER BY V.installed_rank DESC;
END;
