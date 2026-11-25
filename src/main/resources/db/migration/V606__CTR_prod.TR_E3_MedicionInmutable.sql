IF OBJECT_ID(N'[prod].[TR_E3_MedicionInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_MedicionInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_MedicionInmutable
' Descripción            : Protege la integridad de e3 medicion inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E3_MedicionInmutable
ON prod.PlantaMedicionE3 AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 51186, N'Las mediciones históricas no se pueden modificar ni eliminar.', 1;
END;
GO
