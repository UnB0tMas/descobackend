IF OBJECT_ID(N'[prod].[TR_E3_ProduccionInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_ProduccionInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_ProduccionInmutable
' Descripción            : Protege la integridad de e3 produccion inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E3_ProduccionInmutable
ON prod.ProduccionPlantaE3 AFTER UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON;
 THROW 51185,N'La producción histórica no se puede sobrescribir.',1;
END;
GO
