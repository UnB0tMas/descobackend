-- Datos propios de agricultura; crianza mantiene columnas nulas.
IF OBJECT_ID(N'[prod].[GPActividad]', N'U') IS NULL
    THROW 51000, N'No se encontró la tabla de actividades.', 1;
GO

IF COL_LENGTH(N'prod.GPActividad', N'tipo_riego') IS NULL
BEGIN
    ALTER TABLE prod.GPActividad ADD tipo_riego VARCHAR(30) NULL;
END;
GO

IF COL_LENGTH(N'prod.GPActividad', N'fuente_agua') IS NULL
BEGIN
    ALTER TABLE prod.GPActividad ADD fuente_agua NVARCHAR(150) NULL;
END;
GO
