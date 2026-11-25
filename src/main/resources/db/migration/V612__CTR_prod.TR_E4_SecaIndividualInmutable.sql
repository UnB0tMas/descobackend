IF OBJECT_ID(N'[prod].[TR_E4_SecaIndividualInmutable]') IS NOT NULL
    DROP TRIGGER [prod].[TR_E4_SecaIndividualInmutable];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/******************************************************************************************************
' Nombre del Trigger       : prod.TR_E4_SecaIndividualInmutable
' Descripción            : Protege la integridad de e4 seca individual inmutable ante cambios no permitidos.
' Aplicativo / Módulo    : DESCO / prod
*******************************************************************************************************/
CREATE TRIGGER prod.TR_E4_SecaIndividualInmutable ON prod.PlantaMateriaSecaIndividualE4 AFTER UPDATE,DELETE AS
BEGIN
 SET NOCOUNT ON;
 THROW 51383,N'Las mediciones individuales son inmutables.',1;
END;
GO
