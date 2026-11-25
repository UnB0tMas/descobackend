IF OBJECT_ID(N'[prod].[TR_E3_FichaInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E3_FichaInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E3_FichaInmutable
' Descripción            : Protege la integridad de e3 ficha inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E3_FichaInmutable ON prod.PlantaFichaHistorialE3 AFTER UPDATE,DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51187,N'El historial de fichas es inmutable.',1;
END;
GO
