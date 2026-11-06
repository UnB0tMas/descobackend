-- Diagnóstico de solo lectura. No modifica registros ni utiliza transacciones.
-- Ejecutar desde SSMS en DESCO_DB_dev. Los resultados se muestran en la consola SQL.
SET NOCOUNT ON;
DECLARE @correlacion UNIQUEIDENTIFIER = '6ea61f9f-6ae5-4395-bb7c-2d7acd560f82';

SELECT DB_NAME() AS base_actual, @@SERVERNAME AS servidor_actual;

IF OBJECT_ID(N'auditoria.ExpedienteErrorTecnico',N'U') IS NOT NULL
BEGIN
    SELECT TOP (10)
        E.fecha_utc,E.correlacion_id,E.operacion,E.numero_sql,
        E.procedimiento,E.linea_sql,E.mensaje_sql
    FROM auditoria.ExpedienteErrorTecnico AS E
    WHERE E.correlacion_id=@correlacion
    ORDER BY E.error_id DESC;

    SELECT TOP (5)
        E.fecha_utc,E.correlacion_id,E.operacion,E.numero_sql,
        E.procedimiento,E.linea_sql,E.mensaje_sql
    FROM auditoria.ExpedienteErrorTecnico AS E
    WHERE E.operacion='PREDIO_CREAR'
      AND E.fecha_utc>=DATEADD(DAY,-2,SYSUTCDATETIME())
    ORDER BY E.error_id DESC;
END
ELSE
    PRINT N'No está disponible la auditoría E1. Verifique la migración V578.';

SELECT V.nombre, V.tipo, V.existe
FROM (VALUES
  (N'prod.SQ_CodigoPredio',N'SECUENCIA',CASE WHEN OBJECT_ID(N'prod.SQ_CodigoPredio',N'SO') IS NOT NULL THEN 1 ELSE 0 END),
  (N'prod.SQ_CodigoParcela',N'SECUENCIA',CASE WHEN OBJECT_ID(N'prod.SQ_CodigoParcela',N'SO') IS NOT NULL THEN 1 ELSE 0 END),
  (N'prod.PA_E1_Predio_Ins_Registrar',N'PROCEDIMIENTO',CASE WHEN OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar',N'P') IS NOT NULL THEN 1 ELSE 0 END),
  (N'geo.PA_Ubicacion_Ins_Interna',N'PROCEDIMIENTO',CASE WHEN OBJECT_ID(N'geo.PA_Ubicacion_Ins_Interna',N'P') IS NOT NULL THEN 1 ELSE 0 END),
  (N'prod.PredioIdentidad',N'TABLA',CASE WHEN OBJECT_ID(N'prod.PredioIdentidad',N'U') IS NOT NULL THEN 1 ELSE 0 END),
  (N'prod.PredioAmbito',N'TABLA',CASE WHEN OBJECT_ID(N'prod.PredioAmbito',N'U') IS NOT NULL THEN 1 ELSE 0 END)
) AS V(nombre,tipo,existe);

SELECT S.name AS secuencia, CONVERT(BIGINT,S.current_value) AS valor_actual,
       CONVERT(BIGINT,S.increment) AS incremento
FROM sys.sequences AS S
JOIN sys.schemas AS H ON H.schema_id=S.schema_id
WHERE H.name=N'prod' AND S.name IN(N'SQ_CodigoPredio',N'SQ_CodigoParcela');

-- Referencias pendientes de resolución (pueden incluir referencias diferidas legítimas).
SELECT D.referencing_id,OBJECT_SCHEMA_NAME(D.referencing_id) AS esquema,
       OBJECT_NAME(D.referencing_id) AS procedimiento,
       D.referenced_schema_name,D.referenced_entity_name
FROM sys.sql_expression_dependencies AS D
WHERE D.referencing_id IN (OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar'),
                           OBJECT_ID(N'prod.PA_ExpedienteProductivo_Ejecutar'))
  AND D.referenced_id IS NULL
ORDER BY procedimiento,D.referenced_entity_name;
