-- QA sin modificaciones: estado real del alta de predios.
-- El error 208 registrado antes de crear V582 no prueba un fallo posterior.
SET NOCOUNT ON;
SELECT DB_NAME() AS base_datos, @@SERVERNAME AS servidor;
SELECT sch.name AS esquema, seq.name AS secuencia, seq.current_value AS valor_actual
FROM sys.sequences AS seq JOIN sys.schemas AS sch ON seq.schema_id = sch.schema_id
WHERE sch.name = N'prod' AND seq.name IN (N'SQ_CodigoPredio', N'SQ_CodigoParcela');
IF NOT EXISTS (SELECT 1 FROM sys.sequences AS seq JOIN sys.schemas AS sch ON sch.schema_id=seq.schema_id
    WHERE sch.name=N'prod' AND seq.name=N'SQ_CodigoPredio')
   THROW 51583, N'Falta la secuencia del codigo de predio; verificar V582.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.sequences AS seq JOIN sys.schemas AS sch ON sch.schema_id=seq.schema_id
    WHERE sch.name=N'prod' AND seq.name=N'SQ_CodigoParcela')
   THROW 51583, N'Falta la secuencia del codigo de parcela; verificar V582.', 1;
SELECT OBJECT_SCHEMA_NAME(object_id) AS esquema, name AS procedimiento, modify_date
FROM sys.procedures WHERE object_id = OBJECT_ID(N'prod.PA_E1_Predio_Ins_Registrar');
-- Comprobar un nuevo intento tras V582; no reutilizar correlaciones antiguas.
IF OBJECT_ID(N'auditoria.ExpedienteErrorTecnico', N'U') IS NOT NULL
BEGIN
    SELECT TOP (10) E.fecha_utc, E.correlacion_id, E.operacion,
           E.numero_sql, E.procedimiento, E.linea_sql, E.mensaje_sql
    FROM auditoria.ExpedienteErrorTecnico AS E
    WHERE E.operacion = 'PREDIO_CREAR'
    ORDER BY E.error_id DESC;
END;
