-- QA restauración de migración histórica V687 (solo lectura).
-- Ejecutar en DESCO_DB_dev antes del arranque para confirmar que el archivo
-- que falta en Flyway es precisamente la migración original del Dashboard.
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL
    THROW 51687,N'No se encontró dbo.flyway_schema_history; revisar el esquema Flyway configurado.',1;

SELECT installed_rank,version,description,script,checksum,success
FROM dbo.flyway_schema_history
WHERE version IN ('685','686','687','688','689','690')
ORDER BY installed_rank;

IF EXISTS (
    SELECT 1 FROM dbo.flyway_schema_history
    WHERE version='687'
      AND (script<>N'V687__DashboardAPAPPSS_CorreccionesYDiagnostico.sql' OR success<>1)
)
    THROW 51688,N'La V687 registrada no corresponde al Dashboard aplicado correctamente: NO restaurar otro archivo ni ejecutar repair. Verificar el script original de esa version.',1;

IF NOT EXISTS (
    SELECT 1 FROM dbo.flyway_schema_history
    WHERE version='687' AND success=1
)
    THROW 51689,N'La V687 no figura aplicada; comprobar que se consulta la misma base de datos que usa Spring Boot.',1;

SELECT N'V687 Dashboard aplicada: restaurar archivo histórico original y ejecutar clean + arranque Flyway' AS resultado;
