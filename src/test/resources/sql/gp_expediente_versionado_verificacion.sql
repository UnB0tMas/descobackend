-- Ejecutar después de Flyway V475-V486 contra SQL Server de desarrollo.
-- Controles de esquema sin modificar datos ni generar registros ficticios.
SET NOCOUNT ON;
IF OBJECT_ID(N'prod.GPParcelaSolicitud',N'U') IS NULL THROW 51000,N'Falta tabla de idempotencia de parcelas GP.',1;
IF OBJECT_ID(N'prod.GPActividadRevision',N'U') IS NULL THROW 51000,N'Falta historial de metadatos.',1;
IF COL_LENGTH(N'prod.GPCenso',N'cantidad_aproximada') IS NULL THROW 51000,N'Falta columna aproximada.',1;
IF COL_LENGTH(N'prod.GPCenso',N'cantidad_exacta') IS NULL THROW 51000,N'Falta columna exacta.',1;
IF NOT EXISTS(SELECT 1 FROM sys.columns
 WHERE object_id=OBJECT_ID(N'geo.Ubicacion') AND name=N'posicion' AND system_type_id=240)
 THROW 51000,N'La ubicación GPS no está almacenada como geography.',1;
IF EXISTS(SELECT 1 FROM prod.GPCenso WHERE cantidad_aproximada<0 OR cantidad_exacta<0)
 THROW 51000,N'Conteos negativos persistidos.',1;
IF EXISTS(SELECT solicitud_id FROM prod.GPCenso GROUP BY solicitud_id HAVING COUNT_BIG(*)>1)
 THROW 51000,N'Idempotencia de conteos duplicada.',1;
SELECT N'OK: esquema GP y controles básicos presentes' AS resultado;
-- QA transaccional sugerido usando usuarios/UOT reales:
-- 1) predio con parcelas ubicadas en distritos distintos, con y sin centro poblado;
-- 2) creación sin GPS y creación con GPS comprobando geo.Ubicacion.posicion.STSrid=4326;
-- 3) dos actividades (CULTIVO y CRIANZA) en la misma parcela;
-- 4) censo 20->25->10 con motivo, usuario y fecha, sin sobrescribir versiones;
-- 5) reintento con misma solicitud_id: no duplicar;
-- 6) control de concurrencia con versionAnteriorId obsoleta: error 51109;
-- 7) comentario de incidencia con fechaHecho nula y detectada previamente;
-- 8) acceso cruzado de UOT/convenio debe ser rechazado;
-- 9) revisión de alias/estado con motivo y consulta del historial;
-- 10) intento de centro poblado que no corresponde al distrito: debe fallar.
