-- Habilitación de bienes patrimoniales para trabajos de campo.
IF COL_LENGTH(N'logistica.BienInventario', N'permite_salida_tecnica') IS NULL
BEGIN
    ALTER TABLE logistica.BienInventario
        ADD permite_salida_tecnica BIT NOT NULL
            CONSTRAINT DF_BienInventario_PermiteSalidaTecnica DEFAULT (0);
END;
