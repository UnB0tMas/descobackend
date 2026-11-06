-- Mantener las migraciones anteriores intactas. Solo se incorporan columnas históricas.
-- Los registros anteriores sin conteo continúan como históricos sin cantidad, no se inventan valores.
IF COL_LENGTH('prod.GPCenso', 'cantidad_aproximada') IS NULL
    ALTER TABLE prod.GPCenso ADD cantidad_aproximada INT NULL;
GO
IF COL_LENGTH('prod.GPCenso', 'cantidad_exacta') IS NULL
    ALTER TABLE prod.GPCenso ADD cantidad_exacta INT NULL;
GO
UPDATE prod.GPCenso
SET cantidad_aproximada = cantidad,
    cantidad_exacta = CASE WHEN aproximado = 0 THEN cantidad ELSE NULL END
WHERE cantidad_aproximada IS NULL AND cantidad IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_GPCenso_CantidadesVersionadas'
               AND parent_object_id = OBJECT_ID('prod.GPCenso'))
    ALTER TABLE prod.GPCenso ADD CONSTRAINT CK_GPCenso_CantidadesVersionadas
    CHECK ((cantidad_aproximada IS NULL OR cantidad_aproximada >= 0)
       AND (cantidad_exacta IS NULL OR cantidad_exacta >= 0));
GO
-- No se alteran las versiones previas ni el campo histórico 'cantidad'. Las nuevas altas
-- escriben cantidad_aproximada obligatoria y cantidad_exacta opcional.
