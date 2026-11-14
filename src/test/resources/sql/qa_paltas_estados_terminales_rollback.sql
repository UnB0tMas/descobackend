-- QA no persistente. Ejecutar en DESCO_DB_dev, nunca desde Flyway.
-- Requiere al menos una planta sana. Prueba la irreversibilidad y revierte todo.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @planta BIGINT;
SELECT TOP (1) @planta=P.planta_id
FROM prod.PlantaPaltaE3 P WHERE P.estado_actual='SANA' AND P.activo=1
ORDER BY P.planta_id;
IF @planta IS NULL
BEGIN
 PRINT N'QA OMITIDO: no hay plantas sanas en esta base.';
END
ELSE
BEGIN
 BEGIN TRY
  BEGIN TRANSACTION;
  UPDATE prod.PlantaPaltaE3
   SET estado_actual='MUERTA',activo=0,version=version+1
  WHERE planta_id=@planta;
  IF @@ROWCOUNT<>1 THROW 51290,N'No se pudo simular la baja.',1;
  IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3
    WHERE planta_id=@planta AND estado_actual='MUERTA' AND activo=0)
     THROW 51291,N'La baja simulada no actualiza el estado.',1;
  DECLARE @bloqueado BIT=0;
  BEGIN TRY
   UPDATE prod.PlantaPaltaE3 SET version=version+1 WHERE planta_id=@planta;
  END TRY
  BEGIN CATCH
   IF ERROR_NUMBER()=51182 SET @bloqueado=1;
   ELSE THROW;
  END CATCH;
  IF @bloqueado<>1 THROW 51292,N'La planta muerta todavía permite modificaciones.',1;
  ROLLBACK TRANSACTION;
  IF NOT EXISTS(SELECT 1 FROM prod.PlantaPaltaE3
      WHERE planta_id=@planta AND estado_actual='SANA' AND activo=1)
     THROW 51293,N'La prueba no restauró el registro original.',1;
  SELECT 'QA_OK_ROLLBACK' resultado,@planta planta_id;
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
