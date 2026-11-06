-- Verificaciones no destructivas posteriores a Flyway. Los procedimientos no se ejecutan sin sesión real.
SET NOCOUNT ON;
IF OBJECT_ID('prod.GPActividad','U') IS NULL THROW 51900,N'Falta GPActividad.',1;
IF OBJECT_ID('prod.GPCenso','U') IS NULL THROW 51900,N'Falta GPCenso.',1;
IF OBJECT_ID('prod.GPEvento','U') IS NULL THROW 51900,N'Falta GPEvento.',1;
IF OBJECT_ID('prod.GPProblema','U') IS NULL THROW 51900,N'Falta GPProblema.',1;
IF OBJECT_ID('prod.GPTratamiento','U') IS NULL THROW 51900,N'Falta GPTratamiento.',1;
IF OBJECT_ID('prod.FN_GP_Permiso','FN') IS NULL THROW 51900,N'Falta función de autorización.',1;
IF EXISTS(SELECT 1 FROM prod.GPActividad WHERE (rubro='CULTIVO' AND especie_pecuaria_id IS NOT NULL)
 OR (rubro='CRIANZA' AND cultivo_id IS NOT NULL)) THROW 51900,N'Error de aislamiento del rubro.',1;
IF EXISTS(SELECT 1 FROM prod.GPActividad A JOIN prod.Parcela P ON P.parcela_id=A.parcela_id
 WHERE A.predio_id<>P.predio_id) THROW 51900,N'Actividad con predio incorrecto.',1;
SELECT 'OK' AS resultado, COUNT(*) AS totalActividades FROM prod.GPActividad;
SELECT 'CULTIVO' AS rubro,COUNT(*) AS registros FROM prod.GPActividad WHERE rubro='CULTIVO'
UNION ALL SELECT 'CRIANZA',COUNT(*) FROM prod.GPActividad WHERE rubro='CRIANZA';
