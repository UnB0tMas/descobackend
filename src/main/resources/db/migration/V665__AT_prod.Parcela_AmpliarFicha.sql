-- Ampliación conservadora de la ficha de parcela (sin perder registros existentes).
IF OBJECT_ID(N'[prod].[Parcela]', N'U') IS NOT NULL
   AND COL_LENGTH('prod.Parcela', 'observacion') IS NULL
BEGIN
    ALTER TABLE prod.Parcela ADD observacion NVARCHAR(500) NULL;
END;
GO
